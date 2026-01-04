using eCommerce.Model.Requests;
using eCommerce.Model.Responses;
using eCommerce.Model.SearchObjects;

namespace eCommerce.Services
{
    public interface ICuisineTypeService : ICRUDService<CuisineTypeResponse, CuisineTypeSearchObject, CuisineTypeUpsertRequest, CuisineTypeUpsertRequest>
    {
    }
}

