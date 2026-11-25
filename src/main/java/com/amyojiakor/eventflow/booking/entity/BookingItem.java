
package com.amyojiakor.eventflow.booking.entity;

import com.amyojiakor.eventflow.ticket.entity.TicketType;
import jakarta.persistence.*;

import java.math.BigDecimal;

@Entity
@Table(
    name = "booking_items",
    uniqueConstraints = @UniqueConstraint(
        columnNames = {"booking_id", "ticket_type_id"}
    )
)
public class BookingItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "booking_id", nullable = false)
    private Booking booking;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "ticket_type_id", nullable = false)
    private TicketType ticketType;

    @Column(nullable = false)
    private Integer quantity;

    @Column(name = "unit_price", nullable = false, precision = 12, scale = 2)
    private BigDecimal unitPrice;

    @Column(nullable = false, length = 3)
    private String currency;

    protected BookingItem() {
    }

    public BookingItem(Booking booking, TicketType ticketType,
                       Integer quantity, BigDecimal unitPrice,
                       String currency) {
        this.booking = booking;
        this.ticketType = ticketType;
        this.quantity = quantity;
        this.unitPrice = unitPrice;
        this.currency = currency;
    }

    public Long getId() { return id; }
    public Booking getBooking() { return booking; }
    public TicketType getTicketType() { return ticketType; }
    public Integer getQuantity() { return quantity; }
    public BigDecimal getUnitPrice() { return unitPrice; }
    public String getCurrency() { return currency; }

    public void setQuantity(Integer quantity) { this.quantity = quantity; }
}
