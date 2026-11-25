// Kod alanı biçimi (revize R31): yazarken harf/rakam dışı karakterler atılır, büyük harfe çevrilir ve gruplar
// arasına tire kendiliğinden eklenir. Öğretmen kodu 3-3 (K7M-2QX), meydan okuma kodu 4-4 (ABCD-EFGH).
export function formatCode(raw: string, group: number, total: number) {
  const s = raw
    .toUpperCase()
    .replace(/[^0-9A-Z]/g, "")
    .slice(0, total)
  return s.length > group ? `${s.slice(0, group)}-${s.slice(group)}` : s
}

/** Panodaki metni okur (revize R30 "Yapıştır"); izin yoksa ya da desteklenmiyorsa null */
export async function readClipboard(): Promise<string | null> {
  try {
    return (await navigator.clipboard?.readText()) ?? null
  } catch {
    return null
  }
}
