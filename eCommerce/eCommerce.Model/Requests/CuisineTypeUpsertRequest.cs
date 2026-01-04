using System.ComponentModel.DataAnnotations;

namespace eCommerce.Model.Requests
{
    public class CuisineTypeUpsertRequest
    {
        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;
        
        [MaxLength(200)]
        public string? Description { get; set; }
        
        public bool IsActive { get; set; } = true;
    }
}

