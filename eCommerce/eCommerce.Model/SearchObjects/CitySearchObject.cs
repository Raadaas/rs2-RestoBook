namespace eCommerce.Model.SearchObjects
{
    public class CitySearchObject : BaseSearchObject
    {
        public string? Name { get; set; }
        public string? PostalCode { get; set; }
        public string? Region { get; set; }
        public bool? IsActive { get; set; }
    }
}

