package com.example.orderapi.controller;

import com.example.orderapi.model.Order;
import com.example.orderapi.model.OrderRequest;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.UUID;

@RestController
@RequestMapping("/api/orders")
public class OrderController {

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
