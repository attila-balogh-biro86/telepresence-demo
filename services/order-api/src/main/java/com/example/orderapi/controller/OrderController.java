package com.example.orderapi.controller;

import com.example.orderapi.model.Order;
import com.example.orderapi.model.OrderItem;
import com.example.orderapi.model.OrderRequest;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/orders")
public class OrderController {

    @GetMapping
    public List<Order> listOrders() {
        Order order1 = new Order(
                "ORD-001",
                Arrays.asList(
                        new OrderItem(1L, "Wireless Headphones", 1, 79.99),
                        new OrderItem(2L, "Mechanical Keyboard", 1, 129.99)
                ),
                209.98,
                "CONFIRMED",
                LocalDateTime.of(2026, 3, 1, 10, 30, 0)
        );

        Order order2 = new Order(
                "ORD-002",
                Arrays.asList(
                        new OrderItem(3L, "USB-C Hub", 2, 49.99),
                        new OrderItem(4L, "Webcam HD", 1, 89.99)
                ),
                189.97,
                "CONFIRMED",
                LocalDateTime.of(2026, 3, 2, 14, 15, 0)
        );

        Order order3 = new Order(
                "ORD-003",
                List.of(
                        new OrderItem(5L, "Gaming Mouse", 1, 59.99)
                ),
                59.99,
                "CONFIRMED",
                LocalDateTime.of(2026, 3, 3, 9, 0, 0)
        );

        return Arrays.asList(order1, order2, order3);
    }

    @PostMapping
    public Order createOrder(@RequestBody OrderRequest request) {
        double total = request.getItems().stream()
                .mapToDouble(item -> item.getPrice() * item.getQuantity())
                .sum();

        return new Order(
                UUID.randomUUID().toString().substring(0, 8).toUpperCase(),
                request.getItems(),
                total,
                "CONFIRMED",
                LocalDateTime.now()
        );
    }
}
