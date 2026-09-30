package org.example.springbootdemo.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.example.springbootdemo.auth.PermissionService;
import org.example.springbootdemo.bean.TongueObservationRecord;
import org.example.springbootdemo.service.TongueObservationRecordService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@CrossOrigin(origins = {"http://localhost:5173", "http://127.0.0.1:5173"})
@RestController
public class TongueObservationRecordController {

    private final TongueObservationRecordService tongueObservationRecordService;
    private final PermissionService permissionService;

    public TongueObservationRecordController(
            TongueObservationRecordService tongueObservationRecordService,
            PermissionService permissionService) {
        this.tongueObservationRecordService = tongueObservationRecordService;
        this.permissionService = permissionService;
    }

    @GetMapping({"/tongue-observation/current", "/api/tongue-observation/current"})
    public ResponseEntity<Map<String, Object>> listCurrentUserRecords(HttpServletRequest request) {
        Long currentUserId = permissionService.currentUserId(request);
        if (currentUserId == null) {
            return forbidden();
        }
        return ResponseEntity.ok(response(true, "query success", tongueObservationRecordService.listByUserId(currentUserId)));
    }

    @PostMapping({"/tongue-observation", "/api/tongue-observation"})
    public ResponseEntity<Map<String, Object>> addCurrentUserRecord(
            @RequestBody TongueObservationRecord record,
            HttpServletRequest request) {
        Long currentUserId = permissionService.currentUserId(request);
        if (currentUserId == null) {
            return forbidden();
        }
        record.setUserId(currentUserId);
        boolean inserted = tongueObservationRecordService.addRecord(record) > 0;
        return ResponseEntity.ok(response(inserted, inserted ? "tongue record created" : "create failed"));
    }

    private Map<String, Object> response(boolean success, String message) {
        Map<String, Object> response = new HashMap<>();
        response.put("success", success);
        response.put("message", message);
        return response;
    }

    private Map<String, Object> response(boolean success, String message, Object data) {
        Map<String, Object> response = response(success, message);
        response.put("data", data);
        return response;
    }

    private ResponseEntity<Map<String, Object>> forbidden() {
        return ResponseEntity.status(403).body(response(false, "forbidden"));
    }
}
