package com.malinimahal.muhurtham;

import java.time.LocalDate;
import java.time.OffsetDateTime;

public class MuhurthamDate {
    private long id;
    private LocalDate mdate;
    private String note;
    private OffsetDateTime createdAt;

    public long getId() { return id; }
    public void setId(long id) { this.id = id; }

    public LocalDate getMdate() { return mdate; }
    public void setMdate(LocalDate mdate) { this.mdate = mdate; }

    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }
}
