
package com.amyojiakor.eventflow.ticket.entity;

import com.amyojiakor.eventflow.event.entity.Event;
import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "ticket_types")
public class TicketType {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "event_id", nullable = false)
    private Event event;

    @Column(nullable = false)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal price;

    @Column(nullable = false, length = 3)
    private String currency = "NGN";

    @Column(name = "total_quantity", nullable = false)
    private Integer totalQuantity;

    @Column(name = "quantity_sold", nullable = false)
    private Integer quantitySold = 0;

    @Column(name = "quantity_reserved", nullable = false)
    private Integer quantityReserved = 0;

    @Column(name = "quantity_on_hold", nullable = false)
    private Integer quantityOnHold = 0;

    @Column(name = "sales_start_at")
    private Instant salesStartAt;

    @Column(name = "sales_end_at")
    private Instant salesEndAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected TicketType() {
    }

    public TicketType(Event event, String name, String description,
                      BigDecimal price, String currency,
                      Integer totalQuantity) {
        this.event = event;
        this.name = name;
        this.description = description;
        this.price = price;
        this.currency = currency;
        this.totalQuantity = totalQuantity;
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
    public Event getEvent() { return event; }
    public String getName() { return name; }
    public String getDescription() { return description; }
    public BigDecimal getPrice() { return price; }
    public String getCurrency() { return currency; }
    public Integer getTotalQuantity() { return totalQuantity; }
    public Integer getQuantitySold() { return quantitySold; }
    public Integer getQuantityReserved() { return quantityReserved; }
    public Integer getQuantityOnHold() { return quantityOnHold; }
    public Instant getSalesStartAt() { return salesStartAt; }
    public Instant getSalesEndAt() { return salesEndAt; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }

    public void setEvent(Event event) { this.event = event; }
    public void setName(String name) { this.name = name; }
    public void setDescription(String description) { this.description = description; }
    public void setPrice(BigDecimal price) { this.price = price; }
    public void setCurrency(String currency) { this.currency = currency; }
    public void setTotalQuantity(Integer value) { this.totalQuantity = value; }
    public void setSalesStartAt(Instant value) { this.salesStartAt = value; }
    public void setSalesEndAt(Instant value) { this.salesEndAt = value; }
}
