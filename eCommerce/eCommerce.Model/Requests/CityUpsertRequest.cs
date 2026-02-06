using System.ComponentModel.DataAnnotations;

namespace eCommerce.Model.Requests
{
    public class CityUpsertRequest
    {
        [Required(ErrorMessage = "City name is required.")]
        [MaxLength(100, ErrorMessage = "Name must not exceed 100 characters.")]
        public string Name { get; set; } = string.Empty;
        
        [MaxLength(20, ErrorMessage = "Postal code must not exceed 20 characters.")]
        public string? PostalCode { get; set; }
        
        [MaxLength(100, ErrorMessage = "Region must not exceed 100 characters.")]
        public string? Region { get; set; }
        
        public bool IsActive { get; set; } = true;
    }
}

