function yobst_model(;
    params = (
        D0_ = nothing, 
        e_ = nothing, 
        p_ = nothing, 
        N_ = nothing, 
        AnzahlContainer_ = nothing,
        InvestProContainer_ = nothing,
        WeitererInvest_ = nothing,
        ContainerPacht_ = nothing,
        Büromiete_ = nothing,
        Personalkosten_ = nothing,
        WeitereKosten_ = nothing,
        UmsatzProM2ProJahr_ = nothing,
        Umsatzbeteiligung_ = nothing,
        
    )
)
    ### ACHTUNG ###
    # Variablen-Suffix für dieses Modell: 
    # !Bitte überprüfen: Sind die Suffixe überall innerhalb dieses Modells korrekt angebracht?
    ###############

    # Erstelle Variablen zu allen Inputgrößen in params und belege sie mit Werten, wenn ungleich nothing.
    # Format: Inputgrößen sollten am Ende ein _ haben. Variablenname ist dann ohne _.
    # Beispiele: e_ --> e, Pflanzenabstand_ --> Pflanzenabstand, etc
    # Wenn Pflanzenabstand_ = nothing, dann belege Pflanzenabstand nicht.
    # Wenn Pflanzenabstand_ = 17, dann belege Pflanzenabstand = 17, etc
    for param in keys(params)
        variablename = String(param)[1:end-1] * "" # !HIER EBENFALLS SUFFIX ANPASSEN!
        eval(Meta.parse("@variables " * variablename)) # erstelle variable
        !isnothing(params[param]) && eval(Meta.parse(variablename * " = " * string(params[param])))
    end

    # Basisvariablen
    N0 = isnothing(params.N_) ? 100 : params.N_
    @variables begin
        #D0, p, N, e,
        Investment,
        Ddach, T, D[1:N0], Z[1:N0],
        E[1:N0], K[1:N0],
        Pr[1:N0], St[1:N0], In[1:N0], Pe[1:N0], Ma[1:N0], Be[1:N0], Ve[1:N0],
        EBITDA[1:N0], EBIT[1:N0], EBT[1:N0], BR[1:N0], AMOR[1:N0],
        Deckungsbeitrag[1:N0], KostenGemeinFix[1:N0], KostenEinzelVariabel[1:N0], Erfolg[1:N0]
    end

    ### GLEICHUNGEN ###

    # Alle Größen hier sollen PRO MONAT sein
    # zb UmsatzProContainer PRO MONAT

    # Errechnung von Erlösen
    UmsatzProContainer = UmsatzProM2ProJahr * 25 / 12 # Container mit 25m2
    Erlös = AnzahlContainer * UmsatzProContainer * Umsatzbeteiligung

    # Errechnung von Kosten
    Betriebskosten = Büromiete + ContainerPacht + WeitereKosten
    Investment = AnzahlContainer * InvestProContainer + WeitererInvest
    D0 = Investment

    # Erlöse/Kosten
    In = vcat([Investment],[0 for _ in 2:N0]) # Investmentkosten, nur in der ersten Periode
    Pe = [Personalkosten for _ in 1:N0] # Personalkosten
    Ma = [0 for _ in 1:N0] # Materialkosten
    Be = [Betriebskosten for _ in 1:N0] # Betriebskosten
    Ve = [0 for _ in 1:N0] # Vertriebskosten
    K = In + Pe + Ma + Be + Ve #fertig
    E = [Erlös for _ in 1:N0] + vcat([D0], [0 for _ in 2:N0]) # Erlöse mit Darlehen als Startguthaben

    # Darlehen
    # ... hier Darlehensstruktur und Formel definieren
    Ddach = D0 * (1-e) #fix
    T = Ddach / N
    D = [Ddach - (i-1)*T for i in 1:N0]
    Z = p/12 * D

    # KPI: Kosten&Erlösrechnung
    KostenEinzelVariabel = [0 for _ in 1:N0]
    Deckungsbeitrag = E - KostenEinzelVariabel #fertig
    KostenGemeinFix = K
    Erfolg = Deckungsbeitrag - KostenGemeinFix #fertig # sollte gleich wie EBITDA sein

    # KPI: Fibu
    EBITDA = E - K #fertig
    EBIT = EBITDA .- T #fertig
    EBT = EBIT - Z #fertig
    BR = [sum(EBT[1:i]) for i in 1:N0] #fertig
    AMOR = [sum(EBITDA[1:i]) - D0 for i in 1:N0]

    # hier gewünschte Größen ausgeben lassen
    return Dict(
        "T" => T,
        "Z" => Z,
        "Erlöse" => E,
        "Kosten" => K,
        "Deckungsbeitrag" => Deckungsbeitrag,
        "Erfolg" => Erfolg,
        "EBITDA" => EBITDA,
        "EBIT" => EBIT,
        "EBT" => EBT,
        "BR" => BR,
        "AMOR" => AMOR,
    )
end