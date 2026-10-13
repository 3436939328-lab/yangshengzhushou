package org.example.springbootdemo.rewards;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.springbootdemo.ai.AssistantChatReply;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import java.sql.*;
import java.time.*;
import java.util.*;
import java.util.function.Supplier;

@Service
public class RewardsService {
 private final JdbcTemplate jdbc;
 private final TransactionTemplate tx;
 private final ObjectMapper mapper;
 private final Clock clock;
 @Autowired public RewardsService(JdbcTemplate jdbc,PlatformTransactionManager manager,ObjectMapper mapper){this(jdbc,manager,mapper,Clock.systemUTC());}
 public RewardsService(JdbcTemplate jdbc,PlatformTransactionManager manager,ObjectMapper mapper,Clock clock){this.jdbc=jdbc;this.tx=new TransactionTemplate(manager);this.mapper=mapper;this.clock=clock;}
 public record ProductInput(String name,String description,String imageUrl,int points,int stock,boolean active){}
 public record OrderInput(String requestId,Long productId,String recipient,String phone,String address,boolean addressConfirmed){}
 private <T> T transaction(Supplier<T> work){return tx.execute(status->work.get());}
 private String today(){return LocalDate.now(clock.withZone(ZoneId.of("Asia/Shanghai"))).toString();}
 private void lock(Long user){
  if(user==null)throw new RewardsException(401,"Please sign in");
  jdbc.update("INSERT INTO reward_account(user_id,balance,reserved) VALUES (?,0,0) ON DUPLICATE KEY UPDATE user_id=VALUES(user_id)",user);
  jdbc.queryForObject("SELECT balance FROM reward_account WHERE user_id=? FOR UPDATE",Integer.class,user);
  int expired=jdbc.update("UPDATE reward_chat SET status='FAILED',error_message='Request expired; points released' WHERE user_id=? AND status='PENDING' AND expires_at < ?",user,Timestamp.from(clock.instant()));
  if(expired>0)jdbc.update("UPDATE reward_account SET reserved=reserved-? WHERE user_id=?",expired,user);
 }
 public Map<String,Object> account(Long user){return transaction(()->{lock(user);return readAccount(user);});}
 private Map<String,Object> readAccount(Long user){
  return jdbc.queryForObject("SELECT balance,reserved FROM reward_account WHERE user_id=?",(rs,n)->Map.<String,Object>of("balance",rs.getInt(1),"reserved",rs.getInt(2),"available",rs.getInt(1)-rs.getInt(2),"checkedInToday",jdbc.queryForObject("SELECT COUNT(*) FROM reward_ledger WHERE user_id=? AND entry_type='CHECK_IN' AND reference_id=?",Integer.class,user,today())>0,"dailyCheckInPoints",10,"chatCost",1),user);
 }
 public Map<String,Object> checkIn(Long user){return transaction(()->{
  lock(user);
  if(jdbc.queryForObject("SELECT COUNT(*) FROM reward_ledger WHERE user_id=? AND entry_type='CHECK_IN' AND reference_id=?",Integer.class,user,today())==0){
   jdbc.update("UPDATE reward_account SET balance=balance+10 WHERE user_id=?",user);ledgerEntry(user,10,"CHECK_IN",today());
  }return readAccount(user);
 });}
 private void ledgerEntry(Long user,int delta,String type,String reference){jdbc.update("INSERT INTO reward_ledger(user_id,delta,entry_type,reference_id) VALUES (?,?,?,?)",user,delta,type,reference);}
 public List<Map<String,Object>> ledger(Long user){return jdbc.query("SELECT * FROM reward_ledger WHERE user_id=? ORDER BY id DESC LIMIT 200",(rs,n)->Map.of("id",rs.getLong("id"),"delta",rs.getInt("delta"),"type",rs.getString("entry_type"),"reference",rs.getString("reference_id"),"createdAt",rs.getTimestamp("created_at").toInstant().toString()),user);}
 public Map<String,Object> reserveChat(Long user,String requestId,String hash){
  required(requestId,100,"requestId");
  return transaction(()->{
   lock(user);var existing=chatRows(user,requestId);
   if(!existing.isEmpty()){
    if(!hash.equals(existing.get(0).get("payloadHash")))throw new RewardsException(409,"Request ID belongs to different content");
    return existing.get(0);
   }
   if(jdbc.update("UPDATE reward_account SET reserved=reserved+1 WHERE user_id=? AND balance-reserved>=1",user)==0)throw new RewardsException(402,"Insufficient points; check in to earn points");
   jdbc.update("INSERT INTO reward_chat(user_id,request_id,payload_hash,status,expires_at) VALUES (?,?,?,'PENDING',?)",user,requestId,hash,Timestamp.from(clock.instant().plusSeconds(180)));
   return Map.of("status","NEW","requestId",requestId);
  });
 }
 public void completeChat(Long user,String requestId,AssistantChatReply reply){transaction(()->{
  lock(user);var row=chatRows(user,requestId);
  if(row.isEmpty())throw new RewardsException(404,"Request not found");
  if("SUCCEEDED".equals(row.get(0).get("status")))return null;
  if(!"PENDING".equals(row.get(0).get("status")))throw new RewardsException(409,"Request expired; no points charged");
  String json;try{json=mapper.writeValueAsString(reply);}catch(Exception e){throw new IllegalStateException(e);}
  jdbc.update("UPDATE reward_chat SET status='SUCCEEDED',reply_json=? WHERE user_id=? AND request_id=?",json,user,requestId);
  jdbc.update("UPDATE reward_account SET balance=balance-1,reserved=reserved-1 WHERE user_id=?",user);
  ledgerEntry(user,-1,"CHAT",requestId);return null;
 });}
 public void failChat(Long user,String requestId,String error){transaction(()->{
  lock(user);
  int count=jdbc.update("UPDATE reward_chat SET status='FAILED',error_message=? WHERE user_id=? AND request_id=? AND status='PENDING'",error,user,requestId);
  if(count>0)jdbc.update("UPDATE reward_account SET reserved=reserved-1 WHERE user_id=?",user);
  return null;
 });}
 public Map<String,Object> chatResult(Long user,String requestId){return transaction(()->{
  lock(user);var rows=chatRows(user,requestId);if(rows.isEmpty())throw new RewardsException(404,"Request not found");
  var result=new LinkedHashMap<>(rows.get(0));result.remove("payloadHash");return result;
 });}
 private List<Map<String,Object>> chatRows(Long user,String id){return jdbc.query("SELECT * FROM reward_chat WHERE user_id=? AND request_id=?",(rs,n)->{
  var result=new LinkedHashMap<String,Object>();result.put("requestId",id);result.put("status",rs.getString("status"));result.put("payloadHash",rs.getString("payload_hash"));result.put("error",rs.getString("error_message"));
  String json=rs.getString("reply_json");
  try{result.put("reply",json==null?null:mapper.readValue(json,AssistantChatReply.class));}catch(Exception e){throw new IllegalStateException("Stored reply invalid",e);}return result;
 },user,id);}
 public List<Map<String,Object>> products(boolean admin){return jdbc.query("SELECT * FROM reward_product"+(admin?"":" WHERE active=TRUE")+" ORDER BY id",(rs,n)->product(rs));}
 private Map<String,Object> product(ResultSet rs)throws SQLException{return Map.of("id",rs.getLong("id"),"name",rs.getString("name"),"description",rs.getString("description"),"imageUrl",rs.getString("image_url"),"points",rs.getInt("points"),"stock",rs.getInt("stock"),"active",rs.getBoolean("active"));}
 public Map<String,Object> saveProduct(Long id,ProductInput input){
  required(input.name(),100,"name");bounded(input.description(),1000,"description");bounded(input.imageUrl(),1000,"imageUrl");
  if(input.points()<1||input.stock()<0)throw new RewardsException(400,"Points must be positive and stock nonnegative");
  return transaction(()->{
   Long key=id;
   if(key==null){var holder=new GeneratedKeyHolder();jdbc.update(connection->{var statement=connection.prepareStatement("INSERT INTO reward_product(name,description,image_url,points,stock,active) VALUES (?,?,?,?,?,?)",Statement.RETURN_GENERATED_KEYS);statement.setString(1,input.name().trim());statement.setString(2,Objects.toString(input.description(),""));statement.setString(3,Objects.toString(input.imageUrl(),""));statement.setInt(4,input.points());statement.setInt(5,input.stock());statement.setBoolean(6,input.active());return statement;},holder);key=Objects.requireNonNull(holder.getKey()).longValue();}
   else if(jdbc.update("UPDATE reward_product SET name=?,description=?,image_url=?,points=?,stock=?,active=? WHERE id=?",input.name().trim(),Objects.toString(input.description(),""),Objects.toString(input.imageUrl(),""),input.points(),input.stock(),input.active(),key)==0)throw new RewardsException(404,"Product not found");
   return jdbc.queryForObject("SELECT * FROM reward_product WHERE id=?",(rs,n)->product(rs),key);
  });
 }
 public Map<String,Object> order(Long user,OrderInput input){
  required(input.requestId(),100,"requestId");required(input.recipient(),80,"recipient");required(input.phone(),32,"phone");required(input.address(),500,"address");
  if(!input.addressConfirmed()||input.productId()==null)throw new RewardsException(400,"Confirm the delivery address and product");
  return transaction(()->{
   lock(user);var old=jdbc.query("SELECT * FROM reward_order WHERE user_id=? AND request_id=?",(rs,n)->orderRow(rs),user,input.requestId());
   if(!old.isEmpty()){
    var row=old.get(0);if(!row.get("productId").equals(input.productId())||!row.get("recipient").equals(input.recipient())||!row.get("phone").equals(input.phone())||!row.get("address").equals(input.address()))throw new RewardsException(409,"Request ID belongs to a different order");return row;
   }
   var products=jdbc.query("SELECT * FROM reward_product WHERE id=? FOR UPDATE",(rs,n)->product(rs),input.productId());
   if(products.isEmpty())throw new RewardsException(404,"Product not found");var product=products.get(0);
   if(!Boolean.TRUE.equals(product.get("active"))||((Number)product.get("stock")).intValue()<1)throw new RewardsException(409,"Product is out of stock");
   int points=((Number)product.get("points")).intValue();
   if(jdbc.update("UPDATE reward_account SET balance=balance-? WHERE user_id=? AND balance-reserved>=?",points,user,points)==0)throw new RewardsException(402,"Insufficient points");
   jdbc.update("UPDATE reward_product SET stock=stock-1 WHERE id=?",input.productId());String id=UUID.randomUUID().toString();
   jdbc.update("INSERT INTO reward_order(id,user_id,request_id,product_id,product_name,points,recipient,phone,address,status) VALUES (?,?,?,?,?,?,?,?,?,'PENDING')",id,user,input.requestId(),input.productId(),product.get("name"),points,input.recipient(),input.phone(),input.address());ledgerEntry(user,-points,"REDEMPTION",id);
   return jdbc.queryForObject("SELECT * FROM reward_order WHERE id=?",(rs,n)->orderRow(rs),id);
  });
 }
 private Map<String,Object> orderRow(ResultSet rs)throws SQLException {
  var row=new LinkedHashMap<String,Object>();row.put("id",rs.getString("id"));row.put("userId",rs.getLong("user_id"));row.put("productId",rs.getLong("product_id"));row.put("productName",rs.getString("product_name"));row.put("points",rs.getInt("points"));row.put("recipient",rs.getString("recipient"));row.put("phone",rs.getString("phone"));row.put("address",rs.getString("address"));row.put("status",rs.getString("status"));row.put("carrier",rs.getString("carrier"));row.put("trackingNumber",rs.getString("tracking_number"));row.put("createdAt",rs.getTimestamp("created_at").toInstant().toString());return row;
 }
 public List<Map<String,Object>> orders(Long user){return jdbc.query("SELECT * FROM reward_order WHERE user_id=? ORDER BY created_at DESC",(rs,n)->orderRow(rs),user);}
 public List<Map<String,Object>> allOrders(){return jdbc.query("SELECT * FROM reward_order ORDER BY created_at DESC LIMIT 500",(rs,n)->orderRow(rs));}
 public Map<String,Object> fulfill(String id,String carrier,String tracking){
  required(carrier,100,"carrier");required(tracking,100,"trackingNumber");
  return transaction(()->{
   if(jdbc.update("UPDATE reward_order SET status='SHIPPED',carrier=?,tracking_number=? WHERE id=? AND status='PENDING'",carrier,tracking,id)==0)throw new RewardsException(409,"Order not found or already shipped");
   return jdbc.queryForObject("SELECT * FROM reward_order WHERE id=?",(rs,n)->orderRow(rs),id);
  });
 }
 private void required(String text,int max,String field){if(text==null||text.isBlank()||text.length()>max)throw new RewardsException(400,"Invalid "+field);}
 private void bounded(String text,int max,String field){if(text!=null&&text.length()>max)throw new RewardsException(400,"Invalid "+field);}
}
