package com.rantoniaina.relais;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class RelaisApplication {

	public static void main(String[] args) {
		System.out.println("test cache docker");
		SpringApplication.run(RelaisApplication.class, args);
	}

}
