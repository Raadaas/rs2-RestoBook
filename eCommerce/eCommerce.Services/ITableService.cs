using eCommerce.Model.Requests;
using eCommerce.Model.Responses;
using eCommerce.Model.SearchObjects;

namespace eCommerce.Services
{
    public interface ITableService : ICRUDService<TableResponse, TableSearchObject, TableUpsertRequest, TableUpsertRequest>
    {
    }
}

