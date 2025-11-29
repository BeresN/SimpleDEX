"use client";

import { useState, useEffect } from "react";

export default function ClientOnlyWeb3({ children, fallback = null }) {
    const [mounted, setMounted] = useState(false);

    useEffect(() => {
        setMounted(true);
    }, []);

    if (!mounted) {
        return fallback;
    }

    return <>{children}</>;
}
