export type Article = { id: string; title: string; slug: string; summary: string; content: string; category: string; author: string; thumbnail_url: string | null; cover_url: string | null; status: "draft" | "published"; published_at: string | null; created_at: string };
export const categories = ["AI","Technology","Software","Gadget","Digital Business","Cybersecurity","Innovation"];
