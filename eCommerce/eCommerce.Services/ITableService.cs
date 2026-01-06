using eCommerce.Model.Requests;
using eCommerce.Model.Responses;
using eCommerce.Model.SearchObjects;
using System.Threading.Tasks;

namespace eCommerce.Services
{
    public interface ITableService : ICRUDService<TableResponse, TableSearchObject, TableUpsertRequest, TableUpsertRequest>
    {
        Task<object> GetOccupancyAsync(int? restaurantId = null);
    }
}

