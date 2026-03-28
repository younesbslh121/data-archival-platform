package com.archival.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class S3ObjectInfo {
    private String key;
    private long size;
    private String storageClass;
    private Instant lastModified;
}
