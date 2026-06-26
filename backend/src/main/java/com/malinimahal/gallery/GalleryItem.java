package com.malinimahal.gallery;

import java.time.OffsetDateTime;

public class GalleryItem {
    private long id;
    private String mediaType;
    private String filename;
    private String youtubeUrl;
    private String title;
    private int displayOrder;
    private OffsetDateTime createdAt;

    public long getId()                     { return id; }
    public void setId(long id)              { this.id = id; }

    public String getMediaType()            { return mediaType; }
    public void setMediaType(String v)      { this.mediaType = v; }

    public String getFilename()             { return filename; }
    public void setFilename(String v)       { this.filename = v; }

    /** Full URL to the media (Cloudinary URL or null for locally-served files). */
    private String mediaUrl;
    public String getMediaUrl()             { return mediaUrl; }
    public void setMediaUrl(String v)       { this.mediaUrl = v; }

    public String getYoutubeUrl()           { return youtubeUrl; }
    public void setYoutubeUrl(String v)     { this.youtubeUrl = v; }

    public String getTitle()                { return title; }
    public void setTitle(String v)          { this.title = v; }

    public int getDisplayOrder()            { return displayOrder; }
    public void setDisplayOrder(int v)      { this.displayOrder = v; }

    /** 1–4 = pinned to a specific home page section slot; null = not pinned */
    private Integer homeSlot;
    public Integer getHomeSlot()            { return homeSlot; }
    public void setHomeSlot(Integer v)      { this.homeSlot = v; }

    public OffsetDateTime getCreatedAt()    { return createdAt; }
    public void setCreatedAt(OffsetDateTime v) { this.createdAt = v; }
}
