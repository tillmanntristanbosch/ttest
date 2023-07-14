function pfalzbio_model(;
    params = (
        D0_ = nothing, 
        e_ = nothing, 
        p_ = nothing, 
        N_ = nothing, 
        AnzahlContainer_ = nothing,
        Umsatzbeteiligung_ = nothing,
        Personalkosten_ = nothing,
        WeitereKosten_ = nothing,
        DurchschnittlicheContainerEntfernung_ = nothing,
        Kilometerpreis_ = nothing,
        LieferungenProTag_ = nothing,
        UmsatzProM2ProJahr_ = nothing, 
        ProduktionskostenProM2ProJahr_ = nothing,
    )
)
    ### ACHTUNG ###
    # Variablen-Suffix für dieses Modell: _BERND
    # !Bitte überprüfen: Sind die Suffixe überall innerhalb dieses Modells korrekt angebracht?
    ###############

    # Erstelle Variablen zu allen Inputgrößen in params und belege sie mit Werten, wenn ungleich nothing.
    # Format: Inputgrößen sollten am Ende ein _ haben. Variablenname ist dann ohne _.
    # Beispiele: e_ --> e, Pflanzenabstand_ --> Pflanzenabstand, etc
    # Wenn Pflanzenabstand_ = nothing, dann belege Pflanzenabstand nicht.
    # Wenn Pflanzenabstand_ = 17, dann belege Pflanzenabstand = 17, etc
    for param in keys(params)
        variablename = String(param)[1:end-1] * "_BERND" # !HIER EBENFALLS SUFFIX ANPASSEN!
        eval(Meta.parse("@variables " * variablename)) # erstelle variable
        !isnothing(params[param]) && eval(Meta.parse(variablename * " = " * string(params[param])))
    end

    # Basisvariablen
    N0 = isnothing(params.N_) ? 100 : params.N_
    @variables begin
        #D0_BERND, p_BERND, N_BERND, e_BERND,
        Investment_BERND,
        Ddach_BERND, T_BERND, D_BERND[1:N0], Z_BERND[1:N0],
        E_BERND[1:N0], K_BERND[1:N0],
        Pr_BERND[1:N0], St_BERND[1:N0], In_BERND[1:N0], Pe_BERND[1:N0], Ma_BERND[1:N0], Be_BERND[1:N0], Ve_BERND[1:N0],
        EBITDA_BERND[1:N0], EBIT_BERND[1:N0], EBT_BERND[1:N0], BR_BERND[1:N0], AMOR_BERND[1:N0],
        Deckungsbeitrag_BERND[1:N0], KostenGemeinFix_BERND[1:N0], KostenEinzelVariabel_BERND[1:N0], Erfolg_BERND[1:N0]
    end

    ### GLEICHUNGEN ###

    # Errechnung von Erlösen
    UmsatzProContainer_BERND = UmsatzProM2ProJahr_BERND * 25 / 12 # Container mit 25m2
    Erlös_BERND = AnzahlContainer_BERND * UmsatzProContainer_BERND * Umsatzbeteiligung_BERND

    # Errechnung von Kosten
    ProduktionskostenProContainer_BERND = ProduktionskostenProM2ProJahr_BERND * 25 / 12
    Produktionskosten_BERND = ProduktionskostenProContainer_BERND * AnzahlContainer_BERND
    Transportkosten_BERND = DurchschnittlicheContainerEntfernung_BERND * Kilometerpreis_BERND * AnzahlContainer_BERND * LieferungenProTag_BERND
    Investment_BERND = AnzahlContainer_BERND * 9000 # Kosten für Transportfahrzeuge
    D0_BERND = Investment_BERND

    # Erlöse/Kosten
    In_BERND = vcat([Investment_BERND],[0 for _ in 2:N0]) # Investmentkosten, nur in der ersten Periode
    Pe_BERND = [Personalkosten_BERND for _ in 1:N0] # Personalkosten
    Ma_BERND = [Produktionskosten_BERND for _ in 1:N0] # Materialkosten
    Be_BERND = [Transportkosten_BERND + WeitereKosten_BERND for _ in 1:N0] # Betriebskosten
    Ve_BERND = [0 for _ in 1:N0] # Vertriebskosten
    K_BERND = In_BERND + Pe_BERND + Ma_BERND + Be_BERND + Ve_BERND #fix
    E_BERND = [Erlös_BERND for _ in 1:N0] + vcat([D0_BERND], [0 for _ in 2:N0]) # Erlöse mit Darlehen als Startguthaben

    # Darlehen
    # ... hier Darlehensstruktur und Formel definieren
    Ddach_BERND = D0_BERND * (1-e_BERND) #fertig
    T_BERND = Ddach_BERND / N_BERND
    D_BERND = [Ddach_BERND - (i-1)*T_BERND for i in 1:N0]
    Z_BERND = p_BERND/12 * D_BERND

    # KPI: Kosten&Erlösrechnung
    KostenEinzelVariabel_BERND = K_BERND
    Deckungsbeitrag_BERND = E_BERND - KostenEinzelVariabel_BERND #fertig
    KostenGemeinFix_BERND = [0 for _ in 1:N0]
    Erfolg_BERND = Deckungsbeitrag_BERND - KostenGemeinFix_BERND #fertig # sollte gleich wie EBITDA sein

    # KPI: Fibu
    EBITDA_BERND = E_BERND - K_BERND #fertig
    EBIT_BERND = EBITDA_BERND .- T_BERND #fertig
    EBT_BERND = EBIT_BERND - Z_BERND #fertig
    BR_BERND = [sum(EBT_BERND[1:i]) for i in 1:N0] #fertig
    AMOR_BERND = [sum(EBITDA_BERND[1:i]) - D0_BERND for i in 1:N0] #fertig

    # hier gewünschte Größen ausgeben lassen
    return Dict(
        "Erlöse" => E_BERND,
        "Kosten" => K_BERND,
        "Deckungsbeitrag" => Deckungsbeitrag_BERND,
        "Erfolg" => Erfolg_BERND,
        "EBITDA" => EBITDA_BERND,
        "EBIT" => EBIT_BERND,
        "EBT" => EBT_BERND,
        "BR" => BR_BERND,
        "AMOR" => AMOR_BERND,
    )
end