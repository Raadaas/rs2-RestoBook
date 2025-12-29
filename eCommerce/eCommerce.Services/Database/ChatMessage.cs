using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eCommerce.Services.Database
{
    public class ChatMessage
    {
        [Key]
        public int Id { get; set; }
        
        public int ConversationId { get; set; }
        
        [ForeignKey("ConversationId")]
        public ChatConversation Conversation { get; set; } = null!;
        
        public int SenderId { get; set; }
        
        [ForeignKey("SenderId")]
        public User Sender { get; set; } = null!;
        
        [Required]
        [MaxLength(2000)]
        public string MessageText { get; set; } = string.Empty;
        
        public DateTime SentAt { get; set; } = DateTime.UtcNow;
        
        public bool IsRead { get; set; } = false;
        
        public DateTime? ReadAt { get; set; }
    }
}

