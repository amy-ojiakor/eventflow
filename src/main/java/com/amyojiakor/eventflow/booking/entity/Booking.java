
package com.amyojiakor.eventflow.booking.entity;

import com.amyojiakor.eventflow.checkout.entity.CheckoutHold;
import com.amyojiakor.eventflow.event.entity.Event;
import com.amyojiakor.eventflow.user.entity.User;
import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "bookings")
public class Booking {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "event_id", nullable = false)
    private Event event;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "checkout_hold_id", nullable = false, unique = true)
    private CheckoutHold checkoutHold;

    @Column(name = "booking_reference", nullable = false, unique = true)
    private String bookingReference;

    @Column(name = "total_amount", nullable = false, precision = 12, scale = 2)
    private BigDecimal totalAmount;

    @Column(nullable = false, length = 3)
    private String currency;

    @Column(name = "minimum_deposit_percentage",
            nullable = false, precision = 5, scale = 2)
    private BigDecimal minimumDepositPercentage;

    @Column(name = "minimum_deposit_amount",
            nullable = false, precision = 12, scale = 2)
    private BigDecimal minimumDepositAmount;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private BookingStatus status;

    @Column(name = "reserved_at")
    private Instant reservedAt;

    @Column(name = "payment_due_at")
    private Instant paymentDueAt;

    @Column(name = "confirmed_at")
    private Instant confirmedAt;

    @Column(name = "expired_at")
    private Instant expiredAt;

    @Column(name = "cancelled_at")
    private Instant cancelledAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected Booking() {
    }

    public Booking(User user, Event event, CheckoutHold checkoutHold,
                   String bookingReference, BigDecimal totalAmount,
                   String currency, BigDecimal minimumDepositPercentage,
                   BigDecimal minimumDepositAmount) {
        this.user = user;
        this.event = event;
        this.checkoutHold = checkoutHold;
        this.bookingReference = bookingReference;
        this.totalAmount = totalAmount;
        this.currency = currency;
        this.minimumDepositPercentage = minimumDepositPercentage;
        this.minimumDepositAmount = minimumDepositAmount;
        this.status = BookingStatus.PENDING_DEPOSIT;
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
    public User getUser() { return user; }
    public Event getEvent() { return event; }
    public CheckoutHold getCheckoutHold() { return checkoutHold; }
    public String getBookingReference() { return bookingReference; }
    public BigDecimal getTotalAmount() { return totalAmount; }
    public String getCurrency() { return currency; }
    public BigDecimal getMinimumDepositPercentage() { return minimumDepositPercentage; }
    public BigDecimal getMinimumDepositAmount() { return minimumDepositAmount; }
    public BookingStatus getStatus() { return status; }
    public Instant getReservedAt() { return reservedAt; }
    public Instant getPaymentDueAt() { return paymentDueAt; }
    public Instant getConfirmedAt() { return confirmedAt; }
    public Instant getExpiredAt() { return expiredAt; }
    public Instant getCancelledAt() { return cancelledAt; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }

    public void setStatus(BookingStatus status) { this.status = status; }
    public void setReservedAt(Instant reservedAt) { this.reservedAt = reservedAt; }
    public void setPaymentDueAt(Instant paymentDueAt) { this.paymentDueAt = paymentDueAt; }
    public void setConfirmedAt(Instant confirmedAt) { this.confirmedAt = confirmedAt; }
    public void setExpiredAt(Instant expiredAt) { this.expiredAt = expiredAt; }
    public void setCancelledAt(Instant cancelledAt) { this.cancelledAt = cancelledAt; }
}
