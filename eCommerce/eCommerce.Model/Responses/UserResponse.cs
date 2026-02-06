using System;
using System.Collections.Generic;

namespace eCommerce.Model.Responses
{
    public class UserResponse
    {
        public int Id { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Username { get; set; } = string.Empty;
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? LastLoginAt { get; set; }
        public DateTime? PasswordChangedAt { get; set; }
        public string? PhoneNumber { get; set; }
        public string? ImageUrl { get; set; }
        
        public bool IsAdmin { get; set; }
        public bool IsClient { get; set; }
    }
} 