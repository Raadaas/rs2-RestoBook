using System.ComponentModel.DataAnnotations;

namespace eCommerce.Model.Requests
{
    public class CityUpsertRequest
    {
        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;
        
        [MaxLength(20)]
        public string? PostalCode { get; set; }
        
        [MaxLength(100)]
        public string? Region { get; set; }
        
        public bool IsActive { get; set; } = true;
    }
}

