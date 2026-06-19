package com.malinimahal.refund;

import java.time.OffsetDateTime;

public class Refund {
    private long id;
    private String enquiryRef;
    private boolean isMuhurtham;
    private long advancePaise;
    private String replacedByRef;
    private Integer refundPct;
    private Long refundPaise;
    private String status;          // PENDING | PROCESSED | DENIED
    private OffsetDateTime processedAt;
    private OffsetDateTime createdAt;

    public long getId() { return id; }
    public void setId(long id) { this.id = id; }

    public String getEnquiryRef() { return enquiryRef; }
    public void setEnquiryRef(String enquiryRef) { this.enquiryRef = enquiryRef; }

    public boolean isMuhurtham() { return isMuhurtham; }
    public void setMuhurtham(boolean muhurtham) { isMuhurtham = muhurtham; }

    public long getAdvancePaise() { return advancePaise; }
    public void setAdvancePaise(long advancePaise) { this.advancePaise = advancePaise; }

    public String getReplacedByRef() { return replacedByRef; }
    public void setReplacedByRef(String replacedByRef) { this.replacedByRef = replacedByRef; }

    public Integer getRefundPct() { return refundPct; }
    public void setRefundPct(Integer refundPct) { this.refundPct = refundPct; }

    public Long getRefundPaise() { return refundPaise; }
    public void setRefundPaise(Long refundPaise) { this.refundPaise = refundPaise; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public OffsetDateTime getProcessedAt() { return processedAt; }
    public void setProcessedAt(OffsetDateTime processedAt) { this.processedAt = processedAt; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }
}
