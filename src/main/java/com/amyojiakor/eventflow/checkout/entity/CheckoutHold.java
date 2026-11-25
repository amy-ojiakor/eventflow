
package com.amyojiakor.eventflow.checkout.entity;

import com.amyojiakor.eventflow.user.entity.User;
import jakarta.persistence.*;

import java.time.Instant;

@Entity
@Table(name = "checkout_holds")
public class CheckoutHold {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "hold_reference", nullable = false, unique = true)
    private String holdReference;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private CheckoutHoldStatus status;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected CheckoutHold() {
    }

    public CheckoutHold(User user, String holdReference, Instant expiresAt) {
        this.user = user;
        this.holdReference = holdReference;
        this.expiresAt = expiresAt;
        this.status = CheckoutHoldStatus.ACTIVE;
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
    public String getHoldReference() { return holdReference; }
    public CheckoutHoldStatus getStatus() { return status; }
    public Instant getExpiresAt() { return expiresAt; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }

    public void setStatus(CheckoutHoldStatus status) { this.status = status; }
    public void setExpiresAt(Instant expiresAt) { this.expiresAt = expiresAt; }
}
