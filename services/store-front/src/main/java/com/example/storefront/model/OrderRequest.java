package com.example.storefront.model;

import java.util.List;

public class OrderRequest {

    private List<OrderItem> items;

    public OrderRequest() {
    }

    public OrderRequest(List<OrderItem> items) {
        this.items = items;
    }

    public List<OrderItem> getItems() {
        return items;
    }

    public void setItems(List<OrderItem> items) {
        this.items = items;
    }
}
