package com.malinimahal.enquiry;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.LocalDate;
import java.time.OffsetDateTime;

public class Enquiry {

    private long id;
    private String reference;
    private String customerName;
    private String mobile;
    private LocalDate eventDate;
    private LocalDate endDate;
    private String functionType;
    private String rentalType;
    private String message;
    private String status;
    private OffsetDateTime createdAt;
    private OffsetDateTime startDatetime;
    private OffsetDateTime endDatetime;

    /** Input-only: used to compute startDatetime for HALF_DAY and HOURLY. Not stored directly. */
    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
    private String startTime;

    /** Input-only: used to compute endDatetime for HALF_DAY and HOURLY. Not stored directly. */
    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
    private String endTime;

    public long getId() { return id; }
    public void setId(long id) { this.id = id; }

    public String getReference() { return reference; }
    public void setReference(String reference) { this.reference = reference; }

    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }

    public String getMobile() { return mobile; }
    public void setMobile(String mobile) { this.mobile = mobile; }

    public LocalDate getEventDate() { return eventDate; }
    public void setEventDate(LocalDate eventDate) { this.eventDate = eventDate; }

    public LocalDate getEndDate() { return endDate; }
    public void setEndDate(LocalDate endDate) { this.endDate = endDate; }

    public String getFunctionType() { return functionType; }
    public void setFunctionType(String functionType) { this.functionType = functionType; }

    public String getRentalType() { return rentalType; }
    public void setRentalType(String rentalType) { this.rentalType = rentalType; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }

    public OffsetDateTime getStartDatetime() { return startDatetime; }
    public void setStartDatetime(OffsetDateTime startDatetime) { this.startDatetime = startDatetime; }

    public OffsetDateTime getEndDatetime() { return endDatetime; }
    public void setEndDatetime(OffsetDateTime endDatetime) { this.endDatetime = endDatetime; }

    public String getStartTime() { return startTime; }
    public void setStartTime(String startTime) { this.startTime = startTime; }

    public String getEndTime() { return endTime; }
    public void setEndTime(String endTime) { this.endTime = endTime; }

    private boolean isMuhurtham;

    public boolean isMuhurtham() { return isMuhurtham; }
    public void setMuhurtham(boolean isMuhurtham) { this.isMuhurtham = isMuhurtham; }

    // Billing fields — entered by admin after the event
    private Double elecUnits;
    private Double gasKg;
    private Long decorationChargePaise;

    public Double getElecUnits() { return elecUnits; }
    public void setElecUnits(Double elecUnits) { this.elecUnits = elecUnits; }

    public Double getGasKg() { return gasKg; }
    public void setGasKg(Double gasKg) { this.gasKg = gasKg; }

    public Long getDecorationChargePaise() { return decorationChargePaise; }
    public void setDecorationChargePaise(Long decorationChargePaise) { this.decorationChargePaise = decorationChargePaise; }

    // T&C Rule 2: ₹5,000 if customer collects key before 3:00 PM
    private Long earlyEntryChargePaise;
    public Long getEarlyEntryChargePaise() { return earlyEntryChargePaise; }
    public void setEarlyEntryChargePaise(Long earlyEntryChargePaise) { this.earlyEntryChargePaise = earlyEntryChargePaise; }

    // T&C Rule 10: ₹900 per lost room key
    private Long keyLossChargePaise;
    public Long getKeyLossChargePaise() { return keyLossChargePaise; }
    public void setKeyLossChargePaise(Long keyLossChargePaise) { this.keyLossChargePaise = keyLossChargePaise; }
}
