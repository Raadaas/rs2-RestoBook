using System.Linq;
using System.Text;
using System.Text.Json;
using EasyNetQ;
using eCommerce.Services;
using eCommerce.Services.Database;
using eCommerce.WebAPI.Filters;
using eCommerce.WebAPI.Converters;
using eCommerce.WebAPI.Services;
using Mapster;
using MapsterMapper;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Text.Json.Serialization;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddTransient<IUserService, UserService>();
builder.Services.AddTransient<ICityService, CityService>();
builder.Services.AddTransient<ICuisineTypeService, CuisineTypeService>();
builder.Services.AddSingleton<ContentBasedRestaurantRecommender>();
builder.Services.AddTransient<IRestaurantService, RestaurantService>();
builder.Services.AddTransient<ITableService, TableService>();
builder.Services.AddTransient<IMenuItemService, MenuItemService>();
builder.Services.AddTransient<ISpecialOfferService, SpecialOfferService>();
builder.Services.AddTransient<IReservationService, ReservationService>();
builder.Services.AddTransient<IReservationHistoryService, ReservationHistoryService>();
builder.Services.AddTransient<IReviewService, ReviewService>();
builder.Services.AddTransient<IRestaurantStatisticService, RestaurantStatisticService>();
builder.Services.AddTransient<IChatService, ChatService>();
builder.Services.AddTransient<ILoyaltyService, LoyaltyService>();
builder.Services.AddTransient<IRewardService, RewardService>();
builder.Services.AddTransient<IRestaurantGalleryService, RestaurantGalleryService>();
builder.Services.AddTransient<INotificationService, NotificationService>();

// RabbitMQ: publish reservation status changes for user notifications
var rabbitMqConnectionString = builder.Configuration["RabbitMQ"];
if (!string.IsNullOrWhiteSpace(rabbitMqConnectionString))
{
    var bus = RabbitHutch.CreateBus(rabbitMqConnectionString);
    builder.Services.AddSingleton(bus);
    builder.Services.AddSingleton<IReservationNotificationPublisher, RabbitMqReservationNotificationPublisher>();
}
else
{
    builder.Services.AddSingleton<IReservationNotificationPublisher, NoOpReservationNotificationPublisher>();
}

// Register background service for auto-completing reservations
builder.Services.AddHostedService<ReservationAutoCompleteService>();

builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<IAuthService, AuthService>();

builder.Services.Configure<JwtSettings>(builder.Configuration.GetSection("Jwt"));
builder.Services.AddSingleton<IJwtTokenService, JwtTokenService>();

builder.Services.AddMapster();
// Configure database
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") ?? "Server=localhost;Database=eCommerceDb;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True";
builder.Services.AddDatabaseServices(connectionString);

var jwtSecret = builder.Configuration["Jwt:Secret"] ?? throw new InvalidOperationException("Jwt:Secret is required.");
var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? "eCommerce.WebAPI";
var jwtAudience = builder.Configuration["Jwt:Audience"] ?? "eCommerce.Client";

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret)),
            ValidateIssuer = true,
            ValidIssuer = jwtIssuer,
            ValidateAudience = true,
            ValidAudience = jwtAudience,
            ValidateLifetime = true,
            ClockSkew = TimeSpan.Zero
        };
    });


builder.Services.AddControllers(x =>
    {
        x.Filters.Add<ExceptionFilter>();
    })
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
        options.JsonSerializerOptions.Converters.Add(new TimeSpanConverter());
    });

// Validation messages below fields: format { "errors": { "fieldName": ["Message"] } }, keys in camelCase
builder.Services.Configure<ApiBehaviorOptions>(options =>
{
    options.InvalidModelStateResponseFactory = context =>
    {
        var errors = new Dictionary<string, string[]>();
        var jsonOptions = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
        foreach (var kv in context.ModelState)
        {
            if (kv.Value?.Errors.Count > 0)
            {
                var key = kv.Key;
                if (key.Contains('.'))
                    key = key.Split('.').Last();
                var camelKey = jsonOptions.PropertyNamingPolicy?.ConvertName(key) ?? key;
                errors[camelKey] = kv.Value.Errors.Select(e => e.ErrorMessage ?? "Invalid input.").ToArray();
            }
        }
        return new BadRequestObjectResult(new { errors });
    };
});
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        In = ParameterLocation.Header,
        Description = "JWT Bearer token. Example: \"Bearer <token>\""
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme { Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" } },
            Array.Empty<string>()
        }
    });
});


var app = builder.Build();

// Ensure database is created
using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<eCommerceDbContext>();
    dbContext.Database.EnsureCreated();
}

// Configure the HTTP request pipeline.
//if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// Build content-based recommender from restaurant data (TF-IDF + cosine similarity; cross-platform, no native deps)
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<eCommerceDbContext>();
    var recommender = scope.ServiceProvider.GetRequiredService<ContentBasedRestaurantRecommender>();
    var restaurants = await db.Restaurants.Where(r => r.IsActive).ToListAsync();
    var inputs = restaurants.Select(r => new ContentBasedRestaurantRecommender.RestaurantFeatureInput
    {
        RestaurantId = r.Id,
        Name = r.Name ?? "",
        Description = r.Description ?? "",
        CuisineTypeId = r.CuisineTypeId,
        CityId = r.CityId,
        HasParking = r.HasParking ? 1f : 0f,
        HasTerrace = r.HasTerrace ? 1f : 0f,
        IsKidFriendly = r.IsKidFriendly ? 1f : 0f,
        AverageRating = (float)(r.AverageRating ?? 0)
    }).ToList();
    recommender.BuildFromRestaurants(inputs);
}

app.Run();
