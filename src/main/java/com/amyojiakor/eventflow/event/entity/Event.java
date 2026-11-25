
package com.amyojiakor.eventflow.event.entity;

import com.amyojiakor.eventflow.user.entity.User;
import com.amyojiakor.eventflow.venue.entity.Venue;
import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "events")
public class Event {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "venue_id", nullable = false)
    private Venue venue;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "organizer_user_id", nullable = false)
    private User organizer;

    @Column(nullable = false)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "event_date", nullable = false)
    private Instant eventDate;

    @Column(name = "event_end_date")
    private Instant eventEndDate;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private EventStatus status;

    @Column(name = "minimum_deposit_percentage",
            nullable = false, precision = 5, scale = 2)
    private BigDecimal minimumDepositPercentage;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected Event() {
    }

    public Event(Venue venue, User organizer, String name,
                 String description, Instant eventDate,
                 Instant eventEndDate, BigDecimal minimumDepositPercentage) {
        this.venue = venue;
        this.organizer = organizer;
        this.name = name;
        this.description = description;
        this.eventDate = eventDate;
        this.eventEndDate = eventEndDate;
        this.minimumDepositPercentage = minimumDepositPercentage;
        this.status = EventStatus.DRAFT;
    }

    @PrePersist
    protected void onCreate() {
        Instant now = Instant.now();
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = Instant.now();
    }

    public Long getId() { return id; }
    public Venue getVenue() { return venue; }
    public User getOrganizer() { return organizer; }
    public String getName() { return name; }
    public String getDescription() { return description; }
    public Instant getEventDate() { return eventDate; }
    public Instant getEventEndDate() { return eventEndDate; }
    public EventStatus getStatus() { return status; }
    public BigDecimal getMinimumDepositPercentage() { return minimumDepositPercentage; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }

    public void setVenue(Venue venue) { this.venue = venue; }
    public void setOrganizer(User organizer) { this.organizer = organizer; }
    public void setName(String name) { this.name = name; }
    public void setDescription(String description) { this.description = description; }
    public void setEventDate(Instant eventDate) { this.eventDate = eventDate; }
    public void setEventEndDate(Instant eventEndDate) { this.eventEndDate = eventEndDate; }
    public void setStatus(EventStatus status) { this.status = status; }
    public void setMinimumDepositPercentage(BigDecimal value) {
        this.minimumDepositPercentage = value;
    }
}
