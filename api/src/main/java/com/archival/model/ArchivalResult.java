package com.archival.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ArchivalResult {
    private String dataType;
    private int archivedCount;
    private String s3Key;
    private String cutoffDate;
}
