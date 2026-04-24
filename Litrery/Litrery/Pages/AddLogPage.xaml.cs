using Litrery.DataAccess;
using Litrery.Models;

namespace Litrery.Pages;

public partial class AddLogPage : ContentPage
{
    private readonly Vehicle _vehicle;
    private readonly VehicleRepository _repo = new();
    private bool _manualLPer100Km = false;

    public AddLogPage(Vehicle vehicle)
    {
        InitializeComponent();
        _vehicle = vehicle;
        DateEntry.Date = DateTime.Today;
        TimeEntry.Time = DateTime.Now.TimeOfDay;
    }

    private void OnCalculationFieldChanged(object? sender, TextChangedEventArgs e)
    {
        // Only auto-calculate if user hasn't manually overridden
        if (_manualLPer100Km) return;

        if (double.TryParse(KilometresEntry.Text, out var km) &&
            double.TryParse(LitresEntry.Text, out var litres) &&
            km > 0)
        {
            var calculated = Math.Round((litres / km) * 100, 2);
            LPer100KmEntry.Text = calculated.ToString("N2");
        }
        else
        {
            LPer100KmEntry.Text = string.Empty;
        }
    }

    private void OnRecalcClicked(object? sender, EventArgs e)
    {
        _manualLPer100Km = false;

        if (double.TryParse(KilometresEntry.Text, out var km) &&
            double.TryParse(LitresEntry.Text, out var litres) &&
            km > 0)
        {
            var calculated = Math.Round((litres / km) * 100, 2);
            LPer100KmEntry.Text = calculated.ToString("N2");
        }
        else
        {
            LPer100KmEntry.Text = "--";
        }
    }

    protected override void OnAppearing()
    {
        base.OnAppearing();
        // Detect manual edits to L/100km after page loads
        LPer100KmEntry.TextChanged += OnLPer100KmManuallyChanged;
    }

    protected override void OnDisappearing()
    {
        base.OnDisappearing();
        LPer100KmEntry.TextChanged -= OnLPer100KmManuallyChanged;
    }

    private void OnLPer100KmManuallyChanged(object? sender, TextChangedEventArgs e)
    {
        // If the change wasn't triggered by auto-calc, mark as manual
        _manualLPer100Km = true;
    }

    private void OnBarsSliderChanged(object? sender, ValueChangedEventArgs e)
    {
        var bars = (int)Math.Round(e.NewValue);
        BarsSlider.Value = bars;
        BarsLabel.Text = bars == 0 ? "not recorded" : $"{bars}/10";
    }

    private async void OnSaveClicked(object? sender, EventArgs e)
    {
        if (!DateEntry.Date.HasValue || !TimeEntry.Time.HasValue)
        {
            await DisplayAlertAsync("Validation", "Date and Time are required", "OK");
            return;
        }
        
        var dateTime = DateEntry.Date.Value + TimeEntry.Time.Value;

        var bars = (int)Math.Round(BarsSlider.Value);

        var log = new FuelLog
        {
            Date = dateTime,
            KilometresDriven = double.TryParse(KilometresEntry.Text, out var km) ? km : null,
            Litres = double.TryParse(LitresEntry.Text, out var litres) ? litres : null,
            LPer100Km = double.TryParse(LPer100KmEntry.Text, out var lp) ? lp : null,
            CostZar = double.TryParse(CostEntry.Text, out var cost) ? cost : null,
            BarsRemaining = bars == 0 ? null : bars,
            Notes = string.IsNullOrWhiteSpace(NotesEntry.Text) ? null : NotesEntry.Text.Trim()
        };

        _vehicle.Logs ??= [];
        _vehicle.Logs.Add(log);

        try
        {
            await _repo.UpsertVehicle(_vehicle);
            await Application.Current!.MainPage!.Navigation.PopModalAsync();
        }
        catch (Exception ex)
        {
            _vehicle.Logs.Remove(log);
            await DisplayAlert("Error", ex.Message, "OK");
        }
    }

    private async void OnCancelClicked(object? sender, EventArgs e)
    {
        await Application.Current!.MainPage!.Navigation.PopModalAsync();
    }
}