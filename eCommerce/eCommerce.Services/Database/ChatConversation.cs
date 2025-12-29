using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eCommerce.Services.Database
{
    public class ChatConversation
    {
        [Key]
        public int Id { get; set; }
        
        public int UserId { get; set; }
        
        [ForeignKey("UserId")]
        public User User { get; set; } = null!;
        
        public int RestaurantId { get; set; }
        
        [ForeignKey("RestaurantId")]
        public Restaurant Restaurant { get; set; } = null!;
        
        public DateTime StartedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime LastMessageAt { get; set; } = DateTime.UtcNow;
        
        [MaxLength(20)]
        public string Status { get; set; } = string.Empty;
        
        // Navigation properties
        public ICollection<ChatMessage> Messages { get; set; } = new List<ChatMessage>();
    }
}

