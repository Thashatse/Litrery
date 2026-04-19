using Litrery.DataAccess;
using Litrery.Models;

namespace Litrery;

public partial class MainPage : ContentPage
{
    private readonly VehicleRepository _repo = new();

    public MainPage()
    {
        InitializeComponent();
        Loaded += OnPageLoaded;
    }

    private async void OnPageLoaded(object? sender, EventArgs e)
    {
        await LoadVehicles();
    }
    
    protected override async void OnAppearing()
    {
        base.OnAppearing();
        await LoadVehicles();
    }

    private async Task LoadVehicles()
    {
        try
        {
            LoadingIndicator.IsVisible = true;
            LoadingIndicator.IsRunning = true;
            
            var vehicles = await _repo.ReadVehicles();
            VehicleList.ItemsSource = vehicles;
        }
        catch (Exception ex)
        {
            await DisplayAlertAsync("Error", "An error occured loading vehicles, please try again later.", "OK");
        }
        finally
        {
            LoadingIndicator.IsRunning = false;
            LoadingIndicator.IsVisible = false;
        }
    }

    private async void OnAddVehicleClicked(object? sender, EventArgs e)
    {
        var page = new NavigationPage(new Pages.AddVehiclePage());
        await Navigation.PushModalAsync(page);
    }
    
    private async void OnVehicleSelected(object? sender, SelectionChangedEventArgs e)
    {
        if (e.CurrentSelection.FirstOrDefault() is not Vehicle vehicle) return;
        
        VehicleList.SelectedItem = null;
        
        await Navigation.PushAsync(new Pages.VehicleDetailPage(vehicle));
    }
}