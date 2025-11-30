package org.customer.asg_demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class Hello {
    @GetMapping("/hello")
    public String sayHello() {
        return "Hi, welcome to my page!";
    }
}
