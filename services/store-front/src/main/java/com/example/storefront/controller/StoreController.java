package com.example.storefront.controller;

import com.example.storefront.model.Order;
import com.example.storefront.model.OrderItem;
import com.example.storefront.model.OrderRequest;
import com.example.storefront.model.Product;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpMethod;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.client.RestTemplate;

import java.util.List;

@Controller
public class StoreController {

    private final RestTemplate restTemplate;
    private final String productApiUrl;
    private final String orderApiUrl;

    public StoreController(
            RestTemplate restTemplate,
            @Value("${app.product-api-url}") String productApiUrl,
            @Value("${app.order-api-url}") String orderApiUrl) {
        this.restTemplate = restTemplate;
        this.productApiUrl = productApiUrl;
        this.orderApiUrl = orderApiUrl;
    }

    @GetMapping("/")
    public String index(Model model) {
        List<Product> products = List.of();
        try {
            products = restTemplate.exchange(
                    productApiUrl + "/api/products",
                    HttpMethod.GET,
                    null,
                    new ParameterizedTypeReference<List<Product>>() {}
            ).getBody();
        } catch (Exception e) {
            model.addAttribute("error", "Could not load products: " + e.getMessage());
        }
        model.addAttribute("products", products);
        return "index";
    }

    @GetMapping("/search")
    public String search(@RequestParam String q, Model model) {
        List<Product> products = List.of();
        try {
            products = restTemplate.exchange(
                    productApiUrl + "/api/products/search?q=" + q,
                    HttpMethod.GET,
                    null,
                    new ParameterizedTypeReference<List<Product>>() {}
            ).getBody();
        } catch (Exception e) {
            model.addAttribute("error", "Could not search products: " + e.getMessage());
        }
        model.addAttribute("products", products);
        model.addAttribute("searchQuery", q);
        return "index";
    }

    @GetMapping("/orders")
    public String orders(Model model) {
        List<Order> orders = List.of();
        try {
            orders = restTemplate.exchange(
                    orderApiUrl + "/api/orders",
                    HttpMethod.GET,
                    null,
                    new ParameterizedTypeReference<List<Order>>() {}
            ).getBody();
        } catch (Exception e) {
            model.addAttribute("error", "Could not load orders: " + e.getMessage());
        }
        model.addAttribute("orders", orders);
        return "orders";
    }

    @PostMapping("/order")
    public String placeOrder(@RequestParam Long productId,
                             @RequestParam String productName,
                             @RequestParam double price,
                             Model model) {
        try {
            OrderItem item = new OrderItem(productId, productName, 1, price);
            OrderRequest request = new OrderRequest(List.of(item));
            Order order = restTemplate.postForObject(
                    orderApiUrl + "/api/orders",
                    request,
                    Order.class
            );
            model.addAttribute("order", order);
        } catch (Exception e) {
            model.addAttribute("error", "Could not place order: " + e.getMessage());
        }

        // Re-fetch products for the page
        try {
            List<Product> products = restTemplate.exchange(
                    productApiUrl + "/api/products",
                    HttpMethod.GET,
                    null,
                    new ParameterizedTypeReference<List<Product>>() {}
            ).getBody();
            model.addAttribute("products", products);
        } catch (Exception e) {
            model.addAttribute("products", List.of());
        }
        return "index";
    }
}
