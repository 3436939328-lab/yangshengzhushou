package org.example.springbootdemo.rewards;
import jakarta.servlet.http.HttpServletRequest;
import org.example.springbootdemo.auth.PermissionService;
import org.example.springbootdemo.common.result.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api/rewards")
public class RewardsController {
 private final RewardsService service;
 private final PermissionService permissions;
 public RewardsController(RewardsService service,PermissionService permissions){this.service=service;this.permissions=permissions;}
 private Long user(HttpServletRequest request){Long id=permissions.currentUserId(request);if(id==null)throw new RewardsException(401,"Please sign in");return id;}
 private void admin(HttpServletRequest request){user(request);if(!permissions.isAdmin(request))throw new RewardsException(403,"Administrator permission required");}
 @GetMapping("/account") public ApiResponse<?> account(HttpServletRequest request){return ApiResponse.success(service.account(user(request)));}
 @PostMapping("/check-in") public ApiResponse<?> checkIn(HttpServletRequest request){return ApiResponse.success(service.checkIn(user(request)));}
 @GetMapping("/ledger") public ApiResponse<?> ledger(HttpServletRequest request){return ApiResponse.success(service.ledger(user(request)));}
 @GetMapping("/products") public ApiResponse<?> products(HttpServletRequest request){user(request);return ApiResponse.success(service.products(false));}
 @GetMapping("/orders") public ApiResponse<?> orders(HttpServletRequest request){return ApiResponse.success(service.orders(user(request)));}
 @PostMapping("/orders") public ApiResponse<?> order(@RequestBody RewardsService.OrderInput input,HttpServletRequest request){return ApiResponse.success(service.order(user(request),input));}
 @GetMapping("/admin/products") public ApiResponse<?> adminProducts(HttpServletRequest request){admin(request);return ApiResponse.success(service.products(true));}
 @PostMapping("/admin/products") public ApiResponse<?> create(@RequestBody RewardsService.ProductInput input,HttpServletRequest request){admin(request);return ApiResponse.success(service.saveProduct(null,input));}
 @PutMapping("/admin/products/{id}") public ApiResponse<?> update(@PathVariable Long id,@RequestBody RewardsService.ProductInput input,HttpServletRequest request){admin(request);return ApiResponse.success(service.saveProduct(id,input));}
 @GetMapping("/admin/orders") public ApiResponse<?> allOrders(HttpServletRequest request){admin(request);return ApiResponse.success(service.allOrders());}
 @PostMapping("/admin/orders/{id}/fulfill") public ApiResponse<?> fulfill(@PathVariable String id,@RequestBody Map<String,String> input,HttpServletRequest request){admin(request);return ApiResponse.success(service.fulfill(id,input.get("carrier"),input.get("trackingNumber")));}
}
