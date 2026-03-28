package com.archival.service;

import com.archival.model.ArchivalResponse;
import com.archival.model.CostReport;
import com.archival.model.S3ObjectInfo;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.core.SdkBytes;
import software.amazon.awssdk.services.lambda.LambdaClient;
import software.amazon.awssdk.services.lambda.model.InvokeRequest;
import software.amazon.awssdk.services.lambda.model.InvokeResponse;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;

import java.time.Instant;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class ArchivalService {

    private final S3Client s3Client;
    private final LambdaClient lambdaClient;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Value("${archival.s3.bucket-name}")
    private String bucketName;

    @Value("${archival.lambda.function-name}")
    private String lambdaFunctionName;

    // ── S3 Cost per GB/month (us-east-1 pricing) ──
    private static final Map<String, Double> COST_PER_GB = Map.of(
            "STANDARD", 0.023,
            "INTELLIGENT_TIERING", 0.013,
            "GLACIER", 0.004,
            "DEEP_ARCHIVE", 0.00099
    );

    /**
     * Trigger the Lambda function to archive cold data on demand.
     */
    public ArchivalResponse triggerArchival() {
        log.info("Triggering archival Lambda: {}", lambdaFunctionName);

        try {
            InvokeRequest request = InvokeRequest.builder()
                    .functionName(lambdaFunctionName)
                    .payload(SdkBytes.fromUtf8String("{\"source\": \"spring-boot-api\"}"))
                    .build();

            InvokeResponse response = lambdaClient.invoke(request);
            String payload = response.payload().asUtf8String();

            log.info("Lambda response: {}", payload);

            return objectMapper.readValue(payload, ArchivalResponse.class);

        } catch (Exception e) {
            log.error("Failed to invoke Lambda", e);
            return ArchivalResponse.builder()
                    .message("Archival failed: " + e.getMessage())
                    .statusCode(500)
                    .timestamp(Instant.now())
                    .build();
        }
    }

    /**
     * List archived objects in S3, optionally filtered by prefix (logs/ or invoices/).
     */
    public List<S3ObjectInfo> listArchivedObjects(String prefix) {
        log.info("Listing archived objects with prefix: {}", prefix);

        ListObjectsV2Request request = ListObjectsV2Request.builder()
                .bucket(bucketName)
                .prefix(prefix != null ? prefix : "")
                .maxKeys(100)
                .build();

        ListObjectsV2Response response = s3Client.listObjectsV2(request);

        return response.contents().stream()
                .map(obj -> S3ObjectInfo.builder()
                        .key(obj.key())
                        .size(obj.size())
                        .storageClass(obj.storageClassAsString())
                        .lastModified(obj.lastModified())
                        .build())
                .collect(Collectors.toList());
    }

    /**
     * Generate a cost-savings report based on current S3 storage distribution.
     */
    public CostReport generateCostReport() {
        log.info("Generating cost report for bucket: {}", bucketName);

        ListObjectsV2Request request = ListObjectsV2Request.builder()
                .bucket(bucketName)
                .build();

        ListObjectsV2Response response = s3Client.listObjectsV2(request);
        List<S3Object> objects = response.contents();

        Map<String, Long> countByClass = new HashMap<>();
        Map<String, Long> sizeByClass = new HashMap<>();

        for (S3Object obj : objects) {
            String storageClass = obj.storageClassAsString() != null
                    ? obj.storageClassAsString()
                    : "STANDARD";
            countByClass.merge(storageClass, 1L, Long::sum);
            sizeByClass.merge(storageClass, obj.size(), Long::sum);
        }

        // Calculate actual cost
        double actualCost = sizeByClass.entrySet().stream()
                .mapToDouble(e -> {
                    double gbSize = e.getValue() / (1024.0 * 1024.0 * 1024.0);
                    return gbSize * COST_PER_GB.getOrDefault(e.getKey(), 0.023);
                })
                .sum();

        // Calculate cost if everything was in STANDARD
        long totalSize = sizeByClass.values().stream().mapToLong(Long::longValue).sum();
        double standardCost = (totalSize / (1024.0 * 1024.0 * 1024.0)) * COST_PER_GB.get("STANDARD");

        return CostReport.builder()
                .totalObjects(objects.size())
                .objectsByStorageClass(countByClass)
                .sizeByStorageClass(sizeByClass)
                .estimatedMonthlyCostUSD(Math.round(actualCost * 100.0) / 100.0)
                .estimatedSavingsUSD(Math.round((standardCost - actualCost) * 100.0) / 100.0)
                .generatedAt(Instant.now().toString())
                .build();
    }
}
