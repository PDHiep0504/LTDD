using BE1.Models;
using BE1.Repositories;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection"))
);

builder.Services.AddScoped<IProductRepository, ProductRepository>();

builder.Services.AddControllers();

// Swagger/OpenAPI
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Configure CORS: Cross-Origin Resource Sharing, được dịch là "Chia sẻ tài nguyên giữa các nguồn gốc khác nhau
builder.Services.AddCors(options =>
{
    options.AddPolicy(name: "MyAllowOrigins", policy =>
    {
        //Thay bằng địa chỉ localhost khi khởi chạy bên frontend (VSCode)
        policy.WithOrigins("http://127.0.0.1:5500", "http://localhost:5500")
        .AllowAnyHeader()
        .AllowAnyMethod();
    });
    
    // Policy cho phép truy cập từ mọi nguồn (dùng khi test từ điện thoại/thiết bị khác)
    options.AddPolicy(name: "AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
        .AllowAnyHeader()
        .AllowAnyMethod();
    });
});

//IPv4 Address. . . . . . . . . . . : 10.150.0.109
//http://10.150.0.109:5035
builder.WebHost.UseUrls("http://0.0.0.0:5035"); 
var app = builder.Build();

// Swagger luôn bật (để test dễ dàng)
app.UseSwagger();
app.UseSwaggerUI();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    // Middleware cho môi trường production
    app.UseExceptionHandler("/error"); // endpoint xử lý lỗi tuỳ chỉnh (có thể tạo sau)
    app.UseHsts(); // Bắt buộc HTTPS trong production
}

app.UseHttpsRedirection();

// Áp dụng CORS cho API (dùng AllowAll khi test từ nhiều thiết bị)
app.UseCors("AllowAll");

app.UseAuthorization();

app.MapControllers();

app.Run();
