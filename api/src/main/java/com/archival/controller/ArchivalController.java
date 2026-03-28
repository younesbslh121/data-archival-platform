package com.archival.controller;

import com.archival.model.ArchivalResponse;
import com.archival.model.CostReport;
import com.archival.model.S3ObjectInfo;
import com.archival.service.ArchivalService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/archival")
@RequiredArgsConstructor
@Slf4j
public class ArchivalController {

    private final ArchivalService archivalService;

    /**
     * POST /api/v1/archival/trigger
     * Manually trigger the cold data archival process.
     */
    @PostMapping("/trigger")
    public ResponseEntity<ArchivalResponse> triggerArchival() {
        log.info("POST /api/v1/archival/trigger — Manual archival triggered");
        ArchivalResponse response = archivalService.triggerArchival();
        return ResponseEntity.status(response.getStatusCode()).body(response);
    }

    /**
     * GET /api/v1/archival/objects?prefix=logs/
     * List archived objects, optionally filtered by prefix.
     */
    @GetMapping("/objects")
    public ResponseEntity<List<S3ObjectInfo>> listObjects(
            @RequestParam(required = false) String prefix) {
        log.info("GET /api/v1/archival/objects — prefix={}", prefix);
        return ResponseEntity.ok(archivalService.listArchivedObjects(prefix));
    }

    /**
     * GET /api/v1/archival/cost-report
     * Generate a cost-savings report.
     */
    @GetMapping("/cost-report")
    public ResponseEntity<CostReport> getCostReport() {
        log.info("GET /api/v1/archival/cost-report");
        return ResponseEntity.ok(archivalService.generateCostReport());
    }

    /**
     * GET /api/v1/archival/health
     * Health check endpoint.
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        return ResponseEntity.ok(Map.of(
                "status", "UP",
                "service", "data-archival-api"
        ));
    }
}
