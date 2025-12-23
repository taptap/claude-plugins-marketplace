# Go 语言代码检查规则

本文档定义 Go 语言的代码审查规则，覆盖 Bug 检测、代码质量、安全检查、性能优化四个维度。

---

## 1. Bug 检测（Bug Detection）

### 1.1 Error Handling（错误处理）

#### 忽略错误返回值
```go
// ❌ 错误：忽略 error
file, _ := os.Open("data.txt")

// ✅ 正确：检查并处理 error
file, err := os.Open("data.txt")
if err != nil {
    return fmt.Errorf("打开文件失败: %w", err)
}
defer file.Close()
```

#### 错误覆盖
```go
// ❌ 错误：第二次赋值覆盖了第一个 err
data, err := readData()
result, err := processData(data)  // err 被覆盖，第一个错误丢失

// ✅ 正确：使用不同的变量名或立即检查
data, err := readData()
if err != nil {
    return err
}
result, err := processData(data)
if err != nil {
    return err
}
```

#### 错误包装
```go
// ❌ 错误：丢失错误上下文
if err != nil {
    return errors.New("处理失败")
}

// ✅ 正确：使用 %w 包装错误
if err != nil {
    return fmt.Errorf("处理数据失败: %w", err)
}
```

### 1.2 Nil Pointer（空指针）

#### Nil 检查缺失
```go
// ❌ 错误：未检查 nil
func Process(data *Data) {
    data.Value = 10  // panic if data is nil
}

// ✅ 正确：检查 nil
func Process(data *Data) {
    if data == nil {
        return
    }
    data.Value = 10
}
```

#### Map 未初始化
```go
// ❌ 错误：未初始化就使用
var m map[string]int
m["key"] = 1  // panic: assignment to entry in nil map

// ✅ 正确：初始化后使用
m := make(map[string]int)
m["key"] = 1
```

#### Slice 未初始化
```go
// ❌ 错误：可能导致 panic
var slice []int
slice[0] = 1  // panic if slice is nil

// ✅ 正确：检查或初始化
if len(slice) > 0 {
    slice[0] = 1
}
```

### 1.3 Goroutine Leaks（Goroutine 泄漏）

#### 未使用 Context 取消
```go
// ❌ 错误：Goroutine 无法退出
func Start() {
    go func() {
        for {
            doWork()
            time.Sleep(time.Second)
        }
    }()
}

// ✅ 正确：使用 Context 控制生命周期
func Start(ctx context.Context) {
    go func() {
        ticker := time.NewTicker(time.Second)
        defer ticker.Stop()
        for {
            select {
            case <-ctx.Done():
                return
            case <-ticker.C:
                doWork()
            }
        }
    }()
}
```

#### WaitGroup 使用错误
```go
// ❌ 错误：WaitGroup 复制导致死锁
func Process(wg sync.WaitGroup) {
    defer wg.Done()  // 操作的是副本，不会减少计数
    // ...
}

// ✅ 正确：使用指针
func Process(wg *sync.WaitGroup) {
    defer wg.Done()
    // ...
}
```

#### Channel 未关闭
```go
// ❌ 错误：channel 未关闭，接收方可能永远阻塞
func Producer() <-chan int {
    ch := make(chan int)
    go func() {
        for i := 0; i < 10; i++ {
            ch <- i
        }
        // 未 close(ch)
    }()
    return ch
}

// ✅ 正确：关闭 channel
func Producer() <-chan int {
    ch := make(chan int)
    go func() {
        defer close(ch)
        for i := 0; i < 10; i++ {
            ch <- i
        }
    }()
    return ch
}
```

### 1.4 Defer 陷阱

#### Defer 在循环中
```go
// ❌ 错误：defer 在循环结束后才执行，导致资源泄漏
for _, file := range files {
    f, _ := os.Open(file)
    defer f.Close()  // 所有文件在函数结束时才关闭
}

// ✅ 正确：使用匿名函数
for _, file := range files {
    func() {
        f, _ := os.Open(file)
        defer f.Close()
        // process file
    }()
}
```

#### Defer 与返回值
```go
// ❌ 错误：defer 修改不了命名返回值
func Get() int {
    result := 10
    defer func() {
        result = 20  // 不会影响返回值
    }()
    return result  // 返回 10
}

// ✅ 正确：使用命名返回值
func Get() (result int) {
    result = 10
    defer func() {
        result = 20  // 会影响返回值
    }()
    return  // 返回 20
}
```

### 1.5 Mutex 死锁

#### 锁的重入
```go
// ❌ 错误：同一个 Goroutine 重复加锁导致死锁
type Counter struct {
    mu    sync.Mutex
    value int
}

func (c *Counter) Inc() {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.value++
    c.Inc()  // 死锁！
}

// ✅ 正确：避免递归调用或使用 RWMutex
func (c *Counter) Inc() {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.value++
}
```

#### 锁的顺序不一致
```go
// ❌ 错误：锁的获取顺序不一致可能导致死锁
// Goroutine 1
mutex1.Lock()
mutex2.Lock()

// Goroutine 2
mutex2.Lock()
mutex1.Lock()

// ✅ 正确：保持一致的锁顺序
// 两个 Goroutine 都按相同顺序获取锁
mutex1.Lock()
mutex2.Lock()
```

### 1.6 Range 陷阱

#### Range 变量重用
```go
// ❌ 错误：所有 Goroutine 共享同一个变量
for _, v := range values {
    go func() {
        fmt.Println(v)  // v 被所有 Goroutine 共享
    }()
}

// ✅ 正确：传递参数或使用局部变量
for _, v := range values {
    v := v  // 创建新变量
    go func() {
        fmt.Println(v)
    }()
}
```

#### Range Map 的顺序
```go
// ❌ 错误：依赖 map 的遍历顺序
for key, value := range myMap {
    // map 的遍历顺序是随机的！
}

// ✅ 正确：需要顺序时先排序 keys
keys := make([]string, 0, len(myMap))
for k := range myMap {
    keys = append(keys, k)
}
sort.Strings(keys)
for _, k := range keys {
    value := myMap[k]
    // ...
}
```

---

## 2. 代码质量（Code Quality）

### 2.1 命名规范

#### 包命名
```go
// ❌ 错误命名
package myUtils  // 驼峰命名
package my_utils  // 下划线
package utils  // 太通用

// ✅ 正确命名
package httputil  // 小写，简洁，描述性强
package strings
package encoding
```

#### 变量命名
```go
// ❌ 错误：命名不清晰
var d int  // d 代表什么？
var data1, data2 string  // 用数字区分
var usrNm string  // 过度缩写

// ✅ 正确：清晰的命名
var duration int
var firstName, lastName string
var userName string
```

#### 常量命名
```go
// ❌ 错误：Go 不使用全大写
const MAX_SIZE = 100

// ✅ 正确：驼峰命名
const MaxSize = 100
const defaultTimeout = 30
```

#### 缩写规则
```go
// ❌ 错误：不一致的缩写
type Id struct {}  // ID 应该全大写
type HttpServer struct {}  // HTTP 应该全大写

// ✅ 正确：缩写全大写或全小写
type ID struct {}
type HTTPServer struct {}
type xmlParser struct {}  // 非导出时全小写
```

### 2.2 函数设计

#### 函数长度
```go
// ❌ 错误：函数太长（> 50 行）
func ProcessMessage(msg *Message) error {
    // ... 100 lines of code ...
}

// ✅ 正确：拆分为多个函数
func ProcessMessage(msg *Message) error {
    if err := parseMessage(msg); err != nil {
        return err
    }
    if err := validateMessage(msg); err != nil {
        return err
    }
    return saveMessage(msg)
}

func parseMessage(msg *Message) error { /* ... */ }
func validateMessage(msg *Message) error { /* ... */ }
func saveMessage(msg *Message) error { /* ... */ }
```

#### 参数过多
```go
// ❌ 错误：参数太多（> 5 个）
func CreateUser(name, email, phone, address, city, country string) error {
    // ...
}

// ✅ 正确：使用结构体
type UserInfo struct {
    Name    string
    Email   string
    Phone   string
    Address string
    City    string
    Country string
}

func CreateUser(info UserInfo) error {
    // ...
}
```

### 2.3 代码组织

#### 包组织
```go
// ❌ 错误：包过大，职责不清
package service
// 所有服务逻辑都在这里，1000+ 行

// ✅ 正确：按功能拆分
package user
package order
package payment
```

#### 接口定义位置
```go
// ❌ 错误：在实现包中定义接口
package mysql
type UserRepository interface { /* ... */ }

// ✅ 正确：在使用包中定义接口
package service
type UserRepository interface { /* ... */ }
```

### 2.4 注释规范

#### 导出函数注释
```go
// ❌ 错误：缺少注释或注释格式错误
// get user by id
func GetUser(id int) (*User, error) { /* ... */ }

// ✅ 正确：注释以函数名开头
// GetUser retrieves a user by their ID from the database.
func GetUser(id int) (*User, error) { /* ... */ }
```

#### 包注释
```go
// ❌ 错误：缺少包注释
package user

// ✅ 正确：在包声明前添加注释
// Package user provides user management functionality,
// including authentication, authorization, and profile management.
package user
```

### 2.5 Magic Number

```go
// ❌ 错误：硬编码的 magic number
if status == 200 {
    // ...
}
time.Sleep(86400 * time.Second)

// ✅ 正确：定义为常量
const (
    StatusOK      = 200
    DayInSeconds  = 86400
)

if status == StatusOK {
    // ...
}
time.Sleep(DayInSeconds * time.Second)
```

---

## 3. 安全检查（Security）

### 3.1 SQL 注入

```go
// ❌ 错误：SQL 注入漏洞
query := fmt.Sprintf("SELECT * FROM users WHERE id = %s", userID)
db.Query(query)

query := "SELECT * FROM users WHERE name = '" + userName + "'"
db.Query(query)

// ✅ 正确：使用参数化查询
db.Query("SELECT * FROM users WHERE id = ?", userID)
db.Query("SELECT * FROM users WHERE name = ?", userName)
```

### 3.2 命令注入

```go
// ❌ 错误：命令注入漏洞
cmd := exec.Command("sh", "-c", "ls "+userInput)
cmd.Run()

// ✅ 正确：避免 shell，直接传参数
cmd := exec.Command("ls", userInput)
cmd.Run()

// 或者验证输入
if !isValidInput(userInput) {
    return errors.New("invalid input")
}
```

### 3.3 路径遍历

```go
// ❌ 错误：路径遍历漏洞
filePath := "/var/data/" + userInput
os.Open(filePath)  // 用户可以输入 "../../../etc/passwd"

// ✅ 正确：验证和清理路径
filePath := filepath.Join("/var/data", filepath.Clean(userInput))
if !strings.HasPrefix(filePath, "/var/data/") {
    return errors.New("invalid path")
}
os.Open(filePath)
```

### 3.4 敏感信息泄漏

```go
// ❌ 错误：密码记录到日志
log.Info("user login", user.Email, user.Password)

// ❌ 错误：硬编码密钥
const apiKey = "sk-1234567890abcdef"

// ✅ 正确：脱敏和环境变量
log.Info("user login", user.Email, maskPassword(user.Password))

apiKey := os.Getenv("API_KEY")
if apiKey == "" {
    return errors.New("API_KEY not set")
}
```

### 3.5 不安全的加密

```go
// ❌ 错误：使用弱加密算法
import "crypto/md5"
h := md5.New()  // MD5 已被破解

import "crypto/sha1"
h := sha1.New()  // SHA1 已被破解

// ✅ 正确：使用安全的算法
import "crypto/sha256"
h := sha256.New()

import "golang.org/x/crypto/bcrypt"
hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
```

### 3.6 不安全的随机数

```go
// ❌ 错误：math/rand 不适合安全场景
import "math/rand"
token := rand.Int()  // 可预测

// ✅ 正确：使用 crypto/rand
import "crypto/rand"
b := make([]byte, 32)
_, err := rand.Read(b)
if err != nil {
    return err
}
```

---

## 4. 性能优化（Performance）

### 4.1 字符串拼接

```go
// ❌ 错误：循环中使用 + 拼接
var result string
for i := 0; i < 10000; i++ {
    result += fmt.Sprintf("%d,", i)  // O(n²)
}

// ✅ 正确：使用 strings.Builder
var builder strings.Builder
for i := 0; i < 10000; i++ {
    builder.WriteString(fmt.Sprintf("%d,", i))
}
result := builder.String()
```

### 4.2 Slice 预分配

```go
// ❌ 错误：未预分配容量
var items []Item
for i := 0; i < 10000; i++ {
    items = append(items, Item{})  // 多次扩容
}

// ✅ 正确：预分配容量
items := make([]Item, 0, 10000)
for i := 0; i < 10000; i++ {
    items = append(items, Item{})
}
```

### 4.3 Map 预分配

```go
// ❌ 错误：未预分配容量
m := make(map[string]int)
for i := 0; i < 10000; i++ {
    m[fmt.Sprintf("key%d", i)] = i
}

// ✅ 正确：预分配容量
m := make(map[string]int, 10000)
for i := 0; i < 10000; i++ {
    m[fmt.Sprintf("key%d", i)] = i
}
```

### 4.4 不必要的 Goroutine

```go
// ❌ 错误：为小任务创建 Goroutine
for i := 0; i < 10 {
    go func(i int) {
        process(i)  // process 很快完成
    }(i)
}

// ✅ 正确：直接执行
for i := 0; i < 10; i++ {
    process(i)
}
```

### 4.5 锁的粒度

```go
// ❌ 错误：锁的范围太大
mu.Lock()
data := fetchData()  // 耗时操作
processData(data)    // 耗时操作
mu.Unlock()

// ✅ 正确：缩小锁的范围
data := fetchData()
processedData := processData(data)
mu.Lock()
updateSharedState(processedData)  // 只锁关键区域
mu.Unlock()
```

### 4.6 正则表达式预编译

```go
// ❌ 错误：循环中重复编译正则
for _, text := range texts {
    matched, _ := regexp.MatchString(`\d+`, text)
    // ...
}

// ✅ 正确：预编译正则
re := regexp.MustCompile(`\d+`)
for _, text := range texts {
    matched := re.MatchString(text)
    // ...
}
```

### 4.7 数据库 N+1 查询

```go
// ❌ 错误：N+1 查询
users, _ := db.Query("SELECT id FROM users")
for _, user := range users {
    orders, _ := db.Query("SELECT * FROM orders WHERE user_id = ?", user.ID)
    // 执行了 1 + N 次查询
}

// ✅ 正确：批量查询
users, _ := db.Query("SELECT id FROM users")
userIDs := extractIDs(users)
orders, _ := db.Query("SELECT * FROM orders WHERE user_id IN (?)", userIDs)
// 只执行 2 次查询
```

### 4.8 不必要的内存拷贝

```go
// ❌ 错误：传递大对象的值
func Process(data [1024]byte) {
    // 拷贝 1024 字节
}

// ✅ 正确：传递指针
func Process(data *[1024]byte) {
    // 只拷贝指针（8 字节）
}
```

### 4.9 反射性能

```go
// ❌ 错误：过度使用反射
func GetField(obj interface{}, field string) interface{} {
    v := reflect.ValueOf(obj)
    return v.FieldByName(field).Interface()
}

// ✅ 正确：使用类型断言或代码生成
type User struct {
    Name string
    Age  int
}

func GetUserName(u *User) string {
    return u.Name
}
```

---

## 检查清单总结

### Bug 检测优先级
1. ✅ Error handling（忽略错误、错误覆盖）
2. ✅ Nil pointer（未检查 nil、map/slice 未初始化）
3. ✅ Goroutine leaks（缺少 Context、channel 未关闭）
4. ✅ Mutex deadlock（锁重入、锁顺序不一致）
5. ✅ Defer 陷阱（循环中 defer、返回值问题）
6. ✅ Range 陷阱（变量重用、map 顺序）

### 代码质量优先级
1. ✅ 命名规范（包名、变量名、常量名、缩写）
2. ✅ 函数设计（长度、参数数量、职责单一）
3. ✅ 代码组织（包拆分、接口位置）
4. ✅ 注释规范（导出函数、包注释）
5. ✅ Magic number（定义为常量）

### 安全检查优先级
1. ✅ SQL 注入（参数化查询）
2. ✅ 命令注入（避免 shell，验证输入）
3. ✅ 路径遍历（验证和清理路径）
4. ✅ 敏感信息泄漏（脱敏、环境变量）
5. ✅ 不安全的加密（使用 SHA256/bcrypt）
6. ✅ 不安全的随机数（使用 crypto/rand）

### 性能优化优先级
1. ✅ 数据库 N+1 查询（批量查询）
2. ✅ 字符串拼接（strings.Builder）
3. ✅ Slice/Map 预分配（make with capacity）
4. ✅ 锁的粒度（缩小临界区）
5. ✅ 正则预编译（regexp.MustCompile）
6. ✅ 不必要的 Goroutine（直接执行小任务）
7. ✅ 内存拷贝（传指针）
8. ✅ 反射性能（避免过度使用）

---

## 参考资料

- [Effective Go](https://go.dev/doc/effective_go)
- [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments)
- [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md)
- [OWASP Go Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Go_Security_Cheat_Sheet.html)
