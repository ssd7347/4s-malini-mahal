package com.malinimahal.terms;

import java.time.OffsetDateTime;

public class TermsAcceptance {
    private long id;
    private String enquiryRef;
    private String mobile;
    private long versionId;
    private int versionNumber;
    private OffsetDateTime acceptedAt;

    public long getId() { return id; }
    public void setId(long id) { this.id = id; }

    public String getEnquiryRef() { return enquiryRef; }
    public void setEnquiryRef(String enquiryRef) { this.enquiryRef = enquiryRef; }

    public String getMobile() { return mobile; }
    public void setMobile(String mobile) { this.mobile = mobile; }

    public long getVersionId() { return versionId; }
    public void setVersionId(long versionId) { this.versionId = versionId; }

    public int getVersionNumber() { return versionNumber; }
    public void setVersionNumber(int versionNumber) { this.versionNumber = versionNumber; }

    public OffsetDateTime getAcceptedAt() { return acceptedAt; }
    public void setAcceptedAt(OffsetDateTime acceptedAt) { this.acceptedAt = acceptedAt; }
}
