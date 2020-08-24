
{} (:package |app)
  :files $ {}
    |app.lib3 $ {}
      :ns $ [] |ns |app.lib3
        [] |:require $ [] |[] |hsl.core |:refer ([] |[] |hsl)
      :defs $ {}
        |a $ [] |defn |f ([]) ([] |println |18888800) ([] |js/alert "||this is a demo") ([] |println "|\"this is a String") ([] |println "|#\"\\\\code" "|#\"code\\." |:thing |true |app.lib3ddd) ([] |println "|#\"\\\\code" "|#\"code\\." |:thing |true |1xxxx) ([] |range |110 |app.lib3)
        |b $ [] |defn |a ([]) ([] |app.lib3)
        |c $ [] |defn |c ([] |x)
      :proc $ []
      :configs $ {} (:extension nil)
    |app.util.core $ {} (:ns $ [] |ns |app.util.core)
      :defs $ {}
        |cut $ [] |defn |cut ([]) ([] |qq "|\"addad" "|#\"aadd\\dd")
      :proc $ []
    |app.main $ {} (:ns $ [] |ns |app.main)
      :defs $ {}
        |aa $ [] |defn |aa ([]) ([] |1)
        |bb $ [] |defn |bb ([])
      :proc $ []
      :configs $ {}
