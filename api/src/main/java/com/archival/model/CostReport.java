package com.archival.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CostReport {
    private long totalObjects;
    private Map<String, Long> objectsByStorageClass;
    private Map<String, Long> sizeByStorageClass;
    private double estimatedMonthlyCostUSD;
    private double estimatedSavingsUSD;
    private String generatedAt;
}
