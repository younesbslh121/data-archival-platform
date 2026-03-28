package com.archival.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ArchivalResponse {
    private String message;
    private Instant timestamp;
    private int statusCode;
    private List<ArchivalResult> results;
}
