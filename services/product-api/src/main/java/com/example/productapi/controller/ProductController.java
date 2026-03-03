package com.example.productapi.controller;

import com.example.productapi.model.Product;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/products")
public class ProductController {

    private final List<Product> products = List.of(
            new Product(1L, "Wireless Headphones", "Noise-cancelling over-ear headphones", 79.99),
            new Product(2L, "Mechanical Keyboard", "RGB backlit mechanical keyboard", 129.99),
            new Product(3L, "USB-C Hub", "7-in-1 USB-C docking station", 49.99),
            new Product(4L, "Monitor Stand", "Adjustable aluminum monitor stand", 39.99),
            new Product(5L, "Webcam HD", "1080p HD webcam with microphone", 59.99)
    );

    @GetMapping
    public List<Product> getAllProducts() {
        return products;
    }

    @GetMapping("/search")
    public List<Product> searchProducts(@RequestParam(value = "q", required = false, defaultValue = "") String q) {
        if (q.isEmpty()) {
            return products;
        }
        return products.stream()
                .filter(p -> p.getName().toLowerCase().contains(q.toLowerCase()))
                .collect(Collectors.toList());
    }
}
