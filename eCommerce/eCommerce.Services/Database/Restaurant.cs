using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eCommerce.Services.Database
{
    public class Restaurant
    {
        [Key]
        public int Id { get; set; }
        
        public int OwnerId { get; set; }
        
        [ForeignKey("OwnerId")]
        public User Owner { get; set; } = null!;
        
        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;
        
        [MaxLength(1000)]
        public string? Description { get; set; }
        
        [Required]
        [MaxLength(200)]
        public string Address { get; set; } = string.Empty;
        
        public int CityId { get; set; }
        
        [ForeignKey("CityId")]
        public City City { get; set; } = null!;
        
        [Column(TypeName = "decimal(9,6)")]
        public decimal? Latitude { get; set; }
        
        [Column(TypeName = "decimal(9,6)")]
        public decimal? Longitude { get; set; }
        
        [Phone]
        [MaxLength(20)]
        public string? PhoneNumber { get; set; }
        
        [EmailAddress]
        [MaxLength(100)]
        public string? Email { get; set; }
        
        public int CuisineTypeId { get; set; }
        
        [ForeignKey("CuisineTypeId")]
        public CuisineType CuisineType { get; set; } = null!;
        
        [Column(TypeName = "decimal(3,2)")]
        public decimal? AverageRating { get; set; }
        
        public int TotalReviews { get; set; } = 0;
        
        public bool HasParking { get; set; } = false;
        
        public bool HasTerrace { get; set; } = false;
        
        public bool IsKidFriendly { get; set; } = false;
        
        public TimeSpan OpenTime { get; set; }
        
        public TimeSpan CloseTime { get; set; }
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public bool IsActive { get; set; } = true;
        
        // Navigation properties
        public ICollection<Table> Tables { get; set; } = new List<Table>();
        public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
        public ICollection<RestaurantGallery> Gallery { get; set; } = new List<RestaurantGallery>();
        public ICollection<MenuItem> MenuItems { get; set; } = new List<MenuItem>();
        public ICollection<SpecialOffer> SpecialOffers { get; set; } = new List<SpecialOffer>();
        public ICollection<Review> Reviews { get; set; } = new List<Review>();
        public ICollection<RestaurantStatistic> Statistics { get; set; } = new List<RestaurantStatistic>();
        public ICollection<ChatConversation> ChatConversations { get; set; } = new List<ChatConversation>();
        public ICollection<Reward> Rewards { get; set; } = new List<Reward>();
    }
}

