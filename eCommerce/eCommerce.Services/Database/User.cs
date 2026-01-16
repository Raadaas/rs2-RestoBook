using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eCommerce.Services.Database
{
    public class User
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        [MaxLength(50)]
        public string FirstName { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(50)]
        public string LastName { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(100)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(100)]
        public string Username { get; set; } = string.Empty;
        
        public string PasswordHash { get; set; } = string.Empty;
        
        public string PasswordSalt { get; set; } = string.Empty;
        
        public bool IsActive { get; set; } = true;
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime? LastLoginAt { get; set; }
        
        public DateTime? PasswordChangedAt { get; set; }
        
        [Phone]
        [MaxLength(20)]
        public string? PhoneNumber { get; set; }
        
        public int? CityId { get; set; }
        
        [ForeignKey("CityId")]
        public City? City { get; set; }
        
        [MaxLength(100000)]
        public string? ImageUrl { get; set; }
        
        // Navigation properties
        public ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();
        public ICollection<UserPreference> UserPreferences { get; set; } = new List<UserPreference>();
        public ICollection<Restaurant> OwnedRestaurants { get; set; } = new List<Restaurant>();
        public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
        public ICollection<Review> Reviews { get; set; } = new List<Review>();
        public LoyaltyPoint? LoyaltyPoint { get; set; }
        public ICollection<PointsTransaction> PointsTransactions { get; set; } = new List<PointsTransaction>();
        public ICollection<UserReward> UserRewards { get; set; } = new List<UserReward>();
        public ICollection<ChatConversation> ChatConversations { get; set; } = new List<ChatConversation>();
        public ICollection<ChatMessage> SentMessages { get; set; } = new List<ChatMessage>();
        public ICollection<Notification> Notifications { get; set; } = new List<Notification>();
        public ICollection<ReservationHistory> ChangedReservationHistories { get; set; } = new List<ReservationHistory>();
        public ICollection<UserBehavior> UserBehaviors { get; set; } = new List<UserBehavior>();
    }
} 