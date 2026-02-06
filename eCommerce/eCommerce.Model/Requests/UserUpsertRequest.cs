using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace eCommerce.Model.Requests
{
    public class UserUpsertRequest
    {
        [Required(ErrorMessage = "First name is required.")]
        [MaxLength(50, ErrorMessage = "First name must not exceed 50 characters.")]
        public string FirstName { get; set; } = string.Empty;
        
        [Required(ErrorMessage = "Last name is required.")]
        [MaxLength(50, ErrorMessage = "Last name must not exceed 50 characters.")]
        public string LastName { get; set; } = string.Empty;
        
        [Required(ErrorMessage = "Email address is required.")]
        [MaxLength(100, ErrorMessage = "Email must not exceed 100 characters.")]
        [EmailAddress(ErrorMessage = "Enter a valid email address (e.g. user@domain.com).")]
        public string Email { get; set; } = string.Empty;
        
        [Required(ErrorMessage = "Username is required.")]
        [MaxLength(100, ErrorMessage = "Username must not exceed 100 characters.")]
        public string Username { get; set; } = string.Empty;
        
        [MaxLength(20, ErrorMessage = "Phone number must not exceed 20 characters.")]
        [RegularExpression(@"^[\+]?[0-9\s\-\(\)]{9,20}$", ErrorMessage = "Enter a valid phone number (e.g. +1 234 567 8900).")]
        public string? PhoneNumber { get; set; }
        
        [MaxLength(100000)]
        public string? ImageUrl { get; set; }
        
        public bool IsActive { get; set; } = true;
        
        [MinLength(6, ErrorMessage = "Password must be at least 6 characters.")]
        public string? Password { get; set; }
        
        public string? CurrentPassword { get; set; }
        
        public bool IsAdmin { get; set; } = false;
        public bool IsClient { get; set; } = true;
    }
} 