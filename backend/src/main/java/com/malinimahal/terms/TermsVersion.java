package com.malinimahal.terms;

import java.time.OffsetDateTime;

public class TermsVersion {
    private long id;
    private int version;
    private String tamilText;
    private String englishText;
    private String imageFilename;
    private boolean active;
    private OffsetDateTime createdAt;

    public long getId() { return id; }
    public void setId(long id) { this.id = id; }

    public int getVersion() { return version; }
    public void setVersion(int version) { this.version = version; }

    public String getTamilText() { return tamilText; }
    public void setTamilText(String tamilText) { this.tamilText = tamilText; }

    public String getEnglishText() { return englishText; }
    public void setEnglishText(String englishText) { this.englishText = englishText; }

    public String getImageFilename() { return imageFilename; }
    public void setImageFilename(String imageFilename) { this.imageFilename = imageFilename; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }
}
