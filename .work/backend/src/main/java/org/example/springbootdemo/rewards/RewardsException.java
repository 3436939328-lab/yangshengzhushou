package org.example.springbootdemo.rewards;
public class RewardsException extends RuntimeException {
 private final int status;
 public RewardsException(int status,String message){super(message);this.status=status;}
 public int getStatus(){return status;}
}
