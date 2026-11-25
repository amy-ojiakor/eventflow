
package com.amyojiakor.eventflow.checkout.entity;

import com.amyojiakor.eventflow.ticket.entity.TicketType;
import jakarta.persistence.*;

import java.math.BigDecimal;

@Entity
@Table(
    name = "checkout_hold_items",
    uniqueConstraints = @UniqueConstraint(
        columnNames = {"checkout_hold_id", "ticket_type_id"}
    )
)
public class CheckoutHoldItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "checkout_hold_id", nullable = false)
    private CheckoutHold checkoutHold;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "ticket_type_id", nullable = false)
    private TicketType ticketType;

    @Column(nullable = false)
    private Integer quantity;

    @Column(name = "unit_price", nullable = false, precision = 12, scale = 2)
    private BigDecimal unitPrice;

    @Column(nullable = false, length = 3)
    private String currency;

    protected CheckoutHoldItem() {
    }

    public CheckoutHoldItem(CheckoutHold checkoutHold, TicketType ticketType,
                            Integer quantity, BigDecimal unitPrice,
                            String currency) {
        this.checkoutHold = checkoutHold;
        this.ticketType = ticketType;
        this.quantity = quantity;
        this.unitPrice = unitPrice;
        this.currency = currency;
    }

    public Long getId() { return id; }
    public CheckoutHold getCheckoutHold() { return checkoutHold; }
    public TicketType getTicketType() { return ticketType; }
    public Integer getQuantity() { return quantity; }
    public BigDecimal getUnitPrice() { return unitPrice; }
    public String getCurrency() { return currency; }

    public void setQuantity(Integer quantity) { this.quantity = quantity; }
}
