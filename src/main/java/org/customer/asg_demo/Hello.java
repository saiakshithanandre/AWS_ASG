package org.customer.asg_demo;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class Hello {
    @GetMapping("/hello")
    public String sayHello() {
        return "Hi, welcome to my page!";
    }
    @GetMapping("/hi")
    public String sayHi() {
        return "Hi, Akshitha here!";
    }
    @GetMapping("/test")
    public String test() {
        return "ASG Demo Test Page for update and refresh";
    }
    @GetMapping("/HealthCheck")
    public ResponseEntity<?> healthCheck() {
        return ResponseEntity.ok().body("Service is up and running");
    }
}
